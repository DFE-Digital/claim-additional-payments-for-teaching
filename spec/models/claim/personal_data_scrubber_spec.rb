require "rails_helper"

RSpec.describe Claim::PersonalDataScrubber, type: :model do
  let(:over_two_months_ago) { 2.months.ago - 1.day }

  it "does not delete details from a submitted claim" do
    claim = create(:claim, :submitted, updated_at: over_two_months_ago)

    expect { Claim::PersonalDataScrubber.new.scrub_completed_claims }.not_to change { claim.reload.attributes }
  end

  it "does not delete details from an approved but unpaid claim" do
    claim = create(:claim, :approved, updated_at: over_two_months_ago)

    expect { Claim::PersonalDataScrubber.new.scrub_completed_claims }.not_to change { claim.reload.attributes }
  end

  it "does not delete details from a newly rejected claim" do
    claim = create(:claim, :rejected)

    expect { Claim::PersonalDataScrubber.new.scrub_completed_claims }.not_to change { claim.reload.attributes }
  end

  it "does not delete details from a newly paid claim" do
    claim = create(:claim, :approved)
    create(:payment, :with_figures, claims: [claim])

    expect { Claim::PersonalDataScrubber.new.scrub_completed_claims }.not_to change { claim.reload.attributes }
  end

  it "does not delete details from a claim with a rejection which is old but undone" do
    claim = create(:claim, :submitted)
    create(:decision, :rejected, :undone, claim: claim, created_at: over_two_months_ago)

    expect { Claim::PersonalDataScrubber.new.scrub_completed_claims }.not_to change { claim.reload.attributes }
  end

  it "deletes expected details from an old rejected claim, setting a personal_data_removed_at timestamp" do
    freeze_time do
      claim = create(:claim, :submitted)
      create(:decision, :rejected, claim: claim, created_at: over_two_months_ago)

      Claim::PersonalDataScrubber.new.scrub_completed_claims
      cleaned_claim = Claim.find(claim.id)

      expect(cleaned_claim.first_name).to be_nil
      expect(cleaned_claim.middle_name).to be_nil
      expect(cleaned_claim.surname).to be_nil
      expect(cleaned_claim.date_of_birth).to be_nil
      expect(cleaned_claim.address_line_1).to be_nil
      expect(cleaned_claim.address_line_2).to be_nil
      expect(cleaned_claim.address_line_3).to be_nil
      expect(cleaned_claim.address_line_4).to be_nil
      expect(cleaned_claim.postcode).to be_nil
      expect(cleaned_claim.payroll_gender).to be_nil
      expect(cleaned_claim.national_insurance_number).to be_nil
      expect(cleaned_claim.bank_sort_code).to be_nil
      expect(cleaned_claim.bank_account_number).to be_nil
      expect(cleaned_claim.building_society_roll_number).to be_nil
      expect(cleaned_claim.personal_data_removed_at).to eq(Time.zone.now)
    end
  end

  it "deletes expected details from an old paid claim, setting a personal_data_removed_at timestamp" do
    freeze_time do
      claim = create(:claim, :approved)
      create(:payment, :with_figures, claims: [claim], scheduled_payment_date: over_two_months_ago)

      Claim::PersonalDataScrubber.new.scrub_completed_claims
      cleaned_claim = Claim.find(claim.id)

      expect(cleaned_claim.first_name).to be_nil
      expect(cleaned_claim.middle_name).to be_nil
      expect(cleaned_claim.surname).to be_nil
      expect(cleaned_claim.date_of_birth).to be_nil
      expect(cleaned_claim.address_line_1).to be_nil
      expect(cleaned_claim.address_line_2).to be_nil
      expect(cleaned_claim.address_line_3).to be_nil
      expect(cleaned_claim.address_line_4).to be_nil
      expect(cleaned_claim.postcode).to be_nil
      expect(cleaned_claim.payroll_gender).to be_nil
      expect(cleaned_claim.national_insurance_number).to be_nil
      expect(cleaned_claim.bank_sort_code).to be_nil
      expect(cleaned_claim.bank_account_number).to be_nil
      expect(cleaned_claim.building_society_roll_number).to be_nil
      expect(cleaned_claim.personal_data_removed_at).to eq(Time.zone.now)
    end
  end

  it "calculates the date past which claims are considered old at runtime" do
    # Initialise the scrubber, and create a claim
    scrubber = Claim::PersonalDataScrubber.new
    claim = create(:claim, :submitted)
    create(:decision, :rejected, claim: claim)

    # Travel three months forwards. At this point the claim should be considered
    # old enough to scrub information from.
    travel_to(3.months.from_now)
    scrubber.scrub_completed_claims
    cleaned_claim = Claim.find(claim.id)
    expect(cleaned_claim.personal_data_removed_at).to eq(Time.zone.now)
  end

  it "also deletes expected details from the scrubbed claims’ amendments, setting a personal_data_removed_at timestamp on the amendments" do
    claim, amendment = nil
    travel_to over_two_months_ago - 1.week do
      claim = create(:claim, :submitted)
      amendment = create(:amendment, claim: claim, claim_changes: {
        "teacher_reference_number" => [generate(:teacher_reference_number).to_s, claim.teacher_reference_number],
        "payroll_gender" => ["male", claim.payroll_gender],
        "date_of_birth" => [25.years.ago.to_date, claim.date_of_birth],
        "student_loan_plan" => ["plan_1", claim.student_loan_plan],
        "bank_sort_code" => ["457288", claim.bank_sort_code],
        "bank_account_number" => ["84818482", claim.bank_account_number],
        "building_society_roll_number" => ["123456789/ABCD", claim.building_society_roll_number]
      })
      create(:decision, :approved, claim: claim, created_at: over_two_months_ago)
      create(:payment, :with_figures, claims: [claim], scheduled_payment_date: over_two_months_ago)
    end

    freeze_time do
      original_trn_change = amendment.claim_changes["teacher_reference_number"]

      Claim::PersonalDataScrubber.new.scrub_completed_claims

      cleaned_amendment = Amendment.find(amendment.id)

      expect(cleaned_amendment.claim_changes.keys).to match_array(%w[teacher_reference_number payroll_gender date_of_birth student_loan_plan bank_sort_code bank_account_number building_society_roll_number])
      expect(cleaned_amendment.notes).not_to be_nil
      expect(cleaned_amendment.claim_changes["teacher_reference_number"]).to eq(original_trn_change)
      expect(cleaned_amendment.claim_changes["date_of_birth"]).to eq(nil)
      expect(cleaned_amendment.claim_changes["payroll_gender"]).to eq(nil)
      expect(cleaned_amendment.claim_changes["bank_sort_code"]).to eq(nil)
      expect(cleaned_amendment.claim_changes["bank_account_number"]).to eq(nil)
      expect(cleaned_amendment.claim_changes["building_society_roll_number"]).to eq(nil)

      expect(cleaned_amendment.personal_data_removed_at).to eq(Time.zone.now)
    end
  end
end
