require "rails_helper"

RSpec.shared_examples "a claim personal data scrubber" do |policy|
  subject(:personal_data_scrubber) { described_class.new.scrub_completed_claims }

  let(:eligibility_factory) { "#{policy.to_s.underscore}_eligibility" }
  let(:user) { create(:dfe_signin_user) }
  let!(:journey_configuration) { create(:journey_configuration, :targeted_retention_incentive_payments) }
  let(:current_academic_year) { AcademicYear.current }
  let(:last_academic_year) { Time.zone.local(current_academic_year.start_year, 8, 1) }

  it "does not delete details from a submitted claim" do
    claim = create(
      :claim,
      :submitted,
      policy: policy,
      updated_at: last_academic_year
    )

    expect { personal_data_scrubber }.not_to change { claim.reload.attributes }
  end

  it "does not delete details from a submitted but held claim" do
    claim = create(
      :claim,
      :submitted,
      :held,
      policy: policy,
      updated_at: last_academic_year
    )

    expect { personal_data_scrubber }.not_to change { claim.reload.attributes }
  end

  it "does not delete details from a claim with an approval, but undone" do
    claim = create(
      :claim,
      :submitted,
      policy: policy,
      updated_at: last_academic_year
    )
    create(:decision, :approved, :undone, claim: claim)

    expect { personal_data_scrubber }.not_to change { claim.reload.attributes }
  end

  it "does not delete details from an approved but unpaid claim" do
    claim = create(
      :claim,
      :approved,
      policy: policy,
      updated_at: last_academic_year
    )

    expect { personal_data_scrubber }.not_to change { claim.reload.attributes }
  end

  it "does not delete details from a newly rejected claim" do
    claim = create(:claim, :rejected, policy: policy)

    expect { personal_data_scrubber }.not_to change { claim.reload.attributes }
  end

  it "does not delete details from a newly paid claim" do
    claim = create(:claim, :approved, policy: policy)
    create(:payment, :confirmed, :with_figures, claims: [claim])

    expect { personal_data_scrubber }.not_to change { claim.reload.attributes }
  end

  it "does not delete details from a claim with a rejection which is old but undone" do
    claim = create(:claim, :submitted, policy: policy)
    create(:decision, :rejected, :undone, claim: claim, created_at: last_academic_year)

    expect { personal_data_scrubber }.not_to change { claim.reload.attributes }
  end

  it "deletes expected details from a claim with multiple payments all of which have been confirmed" do
    claim = nil

    travel_to 2.months.ago do
      eligibility = build(eligibility_factory, :eligible)
      # Student loans don't have a settable award amount
      if eligibility.has_attribute?(:award_amount)
        eligibility.award_amount = 1500.0
      end
      eligibility.save!
      claim = create(:claim, :approved, policy: policy, eligibility: eligibility)
      create(:payment, :confirmed, :with_figures, claims: [claim], scheduled_payment_date: last_academic_year)
    end

    payment2 = create(:payment, :confirmed, :with_figures, claims: [claim], scheduled_payment_date: last_academic_year)

    if claim.topupable?
      create(:topup, payment: payment2, claim: claim, award_amount: 500, created_by: user)
    end

    expect { personal_data_scrubber }.to change { claim.reload.attributes }
  end

  it "does not delete expected details from a claim for a different policy" do
    other_policy = Policies::POLICIES.detect { |p| p != policy }

    claim = create(:claim, :submitted, policy: other_policy)
    create(:decision, :rejected, claim: claim, created_at: last_academic_year)
    claim.update_attribute :hmrc_bank_validation_responses, ["test"]

    expect { personal_data_scrubber }.not_to change { claim.reload.attributes }
  end

  it "deletes expected details from an old rejected claim, setting a personal_data_removed_at timestamp" do
    freeze_time do
      claim = create(:claim, :submitted, policy: policy)
      create(:decision, :rejected, claim: claim, created_at: last_academic_year)
      claim.update_attribute :hmrc_bank_validation_responses, ["test"]

      personal_data_scrubber
      cleaned_claim = Claim.find(claim.id)

      policy::PERSONAL_DATA_ATTRIBUTES_TO_DELETE.select do |attribute|
        claim.has_attribute?(attribute)
      end.each do |attribute|
        expect(cleaned_claim.public_send(attribute)).to be_nil
      end

      expect(cleaned_claim.personal_data_removed_at).to eq(Time.zone.now)
    end
  end

  it "deletes expected details from an old paid claim, setting a personal_data_removed_at timestamp" do
    freeze_time do
      claim = create(:claim, :approved, policy: policy)
      create(:payment, :confirmed, :with_figures, claims: [claim], scheduled_payment_date: last_academic_year)
      claim.update_attribute :hmrc_bank_validation_responses, ["test"]

      personal_data_scrubber
      cleaned_claim = Claim.find(claim.id)

      policy::PERSONAL_DATA_ATTRIBUTES_TO_DELETE.select do |attribute|
        claim.has_attribute?(attribute)
      end.each do |attribute|
        expect(cleaned_claim.public_send(attribute)).to be_nil
      end
      expect(cleaned_claim.personal_data_removed_at).to eq(Time.zone.now)
    end
  end

  it "only scrubs claims from the previous academic year" do
    # Initialise the scrubber, and create a claim
    scrubber = described_class.new

    claim = create(:claim, :submitted, policy: policy)
    create(:decision, :rejected, claim: claim)

    travel_to(last_academic_year) do
      claim = create(:claim, :submitted, policy: policy)
      create(:decision, :rejected, claim: claim)
    end

    freeze_time do
      scrubber.scrub_completed_claims
      claims = Claim.order(created_at: :asc)
      expect(claims.first.personal_data_removed_at).to eq(Time.zone.now)
      expect(claims.last.personal_data_removed_at).to be_nil
    end
  end

  it "also deletes expected details from the scrubbed claims’ amendments, setting a personal_data_removed_at timestamp on the amendments" do
    claim, amendment = nil
    travel_to last_academic_year - 1.week do
      claim = create(:claim, :submitted, policy: policy)
      claim_changes = {
        "student_loan_plan" => ["plan_1", claim.student_loan_plan],
        "bank_sort_code" => ["457288", claim.bank_sort_code],
        "bank_account_number" => ["84818482", claim.bank_account_number],
        "building_society_roll_number" => ["123456789/ABCD", claim.building_society_roll_number]
      }

      if claim.eligibility.has_attribute?(:teacher_reference_number)
        claim_changes["teacher_reference_number"] = [generate(:teacher_reference_number).to_s, claim.eligibility.teacher_reference_number]
      end

      amendment = create(:amendment, claim: claim, claim_changes: claim_changes)
      create(:decision, :approved, claim: claim, created_at: last_academic_year)
      create(:payment, :confirmed, :with_figures, claims: [claim], scheduled_payment_date: last_academic_year)
    end

    freeze_time do
      original_trn_change = amendment.claim_changes["teacher_reference_number"]

      personal_data_scrubber

      cleaned_amendment = Amendment.find(amendment.id)

      expected_claim_changed_attributes = %w[
        student_loan_plan
        bank_sort_code
        bank_account_number
        building_society_roll_number
      ]

      if claim.eligibility.has_attribute?(:teacher_reference_number)
        expected_claim_changed_attributes << "teacher_reference_number"
      end

      expect(cleaned_amendment.claim_changes.keys).to match_array(expected_claim_changed_attributes)
      expect(cleaned_amendment.notes).not_to be_nil
      if claim.eligibility.has_attribute?(:teacher_reference_number)
        expect(cleaned_amendment.claim_changes["teacher_reference_number"]).to eq(original_trn_change)
      end
      expect(cleaned_amendment.claim_changes["bank_sort_code"]).to eq(nil)
      expect(cleaned_amendment.claim_changes["bank_account_number"]).to eq(nil)
      expect(cleaned_amendment.claim_changes["building_society_roll_number"]).to eq(nil)

      expect(cleaned_amendment.personal_data_removed_at).to eq(Time.zone.now)
    end
  end

  it "removes personal details from the journey session too" do
    journey = Journeys.for_policy(policy)
    session_name = journey::I18N_NAMESPACE

    session_for_approved_claim = create(
      "#{session_name}_session",
      answers: build(
        "#{session_name}_answers",
        :submittable
      )
    )

    session_for_rejected_claim = create(
      "#{session_name}_session",
      answers: build(
        "#{session_name}_answers",
        :submittable
      )
    )

    approved_claim = create(
      :claim,
      :submitted,
      policy: policy,
      journey_session: session_for_approved_claim
    )

    create(
      :decision,
      :approved,
      claim: approved_claim,
      created_at: last_academic_year
    )

    create(
      :payment,
      :confirmed,
      :with_figures,
      claims: [approved_claim],
      scheduled_payment_date: last_academic_year
    )

    rejected_claim = create(
      :claim,
      :submitted,
      policy: policy,
      journey_session: session_for_rejected_claim
    )

    create(
      :decision,
      :rejected,
      claim: rejected_claim,
      created_at: last_academic_year
    )

    personal_data_scrubber

    policy::PERSONAL_DATA_ATTRIBUTES_TO_DELETE.select do |attribute|
      session_for_approved_claim.answers.respond_to?(attribute)
    end.each do |attribute|
      expect(
        session_for_approved_claim.reload.answers.public_send(attribute)
      ).to be_blank

      expect(
        session_for_rejected_claim.reload.answers.public_send(attribute)
      ).to be_blank
    end
  end
end
