require "rails_helper"

RSpec.describe FurtherEducationPayments::Providers::Claims::Stats do
  let(:provider) { create(:eligible_fe_provider, :with_school) }
  let(:other_provider) { create(:eligible_fe_provider, :with_school) }

  subject { described_class.new(provider: provider) }

  let!(:journey_configuration) do
    create(:journey_configuration, :further_education_payments)
  end

  describe "#rejected_count" do
    it "includes rejected and does need QA" do
      eligibility = create(
        :further_education_payments_eligibility,
        :provider_verification_completed,
        school: provider.school
      )

      create(
        :claim,
        :further_education,
        :rejected,
        :does_not_require_qa,
        eligibility:,
        academic_year: journey_configuration.current_academic_year
      )

      expect(subject.rejected_count).to eql(1)
    end

    it "includes rejected, requires QA and passed QA" do
      eligibility = create(
        :further_education_payments_eligibility,
        :provider_verification_completed,
        school: provider.school
      )

      create(
        :claim,
        :further_education,
        :rejected,
        :qa_completed,
        eligibility:,
        academic_year: journey_configuration.current_academic_year
      )

      expect(subject.rejected_count).to eql(1)
    end

    it "excludes rejected, requires QA and QA not completed" do
      eligibility = create(
        :further_education_payments_eligibility,
        :provider_verification_completed,
        school: provider.school
      )

      create(
        :claim,
        :further_education,
        :rejected,
        :flagged_for_qa,
        eligibility:,
        academic_year: journey_configuration.current_academic_year
      )

      expect(subject.rejected_count).to be_zero
    end

    it "excludes claims from other schools" do
      eligibility = create(
        :further_education_payments_eligibility,
        :provider_verification_completed,
        school: other_provider.school
      )

      create(
        :claim,
        :further_education,
        :rejected,
        eligibility:,
        academic_year: journey_configuration.current_academic_year
      )

      expect(subject.rejected_count).to be_zero
    end

    it "excludes claims in other states" do
      eligibility = create(
        :further_education_payments_eligibility,
        :provider_verification_completed,
        school: provider.school
      )

      create(
        :claim,
        :further_education,
        :approved,
        eligibility:,
        academic_year: journey_configuration.current_academic_year
      )

      expect(subject.rejected_count).to be_zero
    end
  end

  describe "#approved_count" do
    it "includes approved and does need QA" do
      eligibility = create(
        :further_education_payments_eligibility,
        :provider_verification_completed,
        school: provider.school
      )

      create(
        :claim,
        :further_education,
        :approved,
        :does_not_require_qa,
        eligibility:,
        academic_year: journey_configuration.current_academic_year
      )

      expect(subject.approved_count).to eql(1)
    end

    it "includes approved, requires QA and passed QA" do
      eligibility = create(
        :further_education_payments_eligibility,
        :provider_verification_completed,
        school: provider.school
      )

      create(
        :claim,
        :further_education,
        :approved,
        :qa_completed,
        eligibility:,
        academic_year: journey_configuration.current_academic_year
      )

      expect(subject.approved_count).to eql(1)
    end

    it "excludes approved, requires QA and QA not completed" do
      eligibility = create(
        :further_education_payments_eligibility,
        :provider_verification_completed,
        school: provider.school
      )

      create(
        :claim,
        :further_education,
        :approved,
        :flagged_for_qa,
        eligibility:,
        academic_year: journey_configuration.current_academic_year
      )

      expect(subject.approved_count).to be_zero
    end

    it "excludes claims from other schools" do
      eligibility = create(
        :further_education_payments_eligibility,
        :provider_verification_completed,
        school: other_provider.school
      )

      create(
        :claim,
        :further_education,
        :approved,
        eligibility:,
        academic_year: journey_configuration.current_academic_year
      )

      expect(subject.approved_count).to be_zero
    end

    it "excludes claims in other states" do
      eligibility = create(
        :further_education_payments_eligibility,
        :provider_verification_completed,
        school: provider.school
      )

      create(
        :claim,
        :further_education,
        :rejected,
        eligibility:,
        academic_year: journey_configuration.current_academic_year
      )

      expect(subject.approved_count).to be_zero
    end
  end

  describe "#pending_decision_count" do
    it "returns correct value" do
      eligibility = create(
        :further_education_payments_eligibility,
        :provider_verification_completed,
        school: provider.school
      )

      create(
        :claim,
        :further_education,
        eligibility:,
        academic_year: journey_configuration.current_academic_year
      )

      expect(subject.pending_decision_count).to eql(1)
    end

    it "excludes claims from other schools" do
      eligibility = create(
        :further_education_payments_eligibility,
        :provider_verification_completed,
        school: other_provider.school
      )

      create(
        :claim,
        :further_education,
        eligibility:,
        academic_year: journey_configuration.current_academic_year
      )

      expect(subject.pending_decision_count).to be_zero
    end

    it "excludes claims in other states" do
      eligibility = create(
        :further_education_payments_eligibility,
        :provider_verification_completed,
        school: provider.school
      )

      create(
        :claim,
        :further_education,
        :approved,
        eligibility:,
        academic_year: journey_configuration.current_academic_year
      )

      eligibility = create(
        :further_education_payments_eligibility,
        :provider_verification_completed,
        school: provider.school
      )

      create(
        :claim,
        :further_education,
        :rejected,
        eligibility:,
        academic_year: journey_configuration.current_academic_year
      )

      expect(subject.pending_decision_count).to be_zero
    end

    it "excludes unverified claims" do
      eligibility = create(
        :further_education_payments_eligibility,
        school: provider.school
      )

      create(
        :claim,
        :further_education,
        eligibility:,
        academic_year: journey_configuration.current_academic_year
      )

      expect(subject.pending_decision_count).to be_zero
    end
  end

  describe "weekly email counts" do
    before do
      [
        [{}, %i[further_education submitted]],
        [{provider_verification_started_at: 1.day.ago}, %i[further_education submitted]],
        [{provider_verification_deadline: 1.day.ago}, %i[further_education submitted]],
        [{}, %i[further_education rejected]],
        [{provider_verification_started_at: 1.day.ago}, %i[further_education rejected]],
        [{provider_verification_deadline: 1.day.ago}, %i[further_education rejected]]
      ].each do |eligibility_attributes, claim_traits|
        create(
          :further_education_payments_eligibility,
          :eligible,
          school: provider.school,
          **eligibility_attributes,
          claim: create(
            :claim,
            *claim_traits,
            academic_year: journey_configuration.current_academic_year
          )
        )
      end
    end

    it "counts overdue unverified, not rejected claims" do
      expect(subject.unverified_overdue_count).to eq(1)
    end

    it "counts in progress unverified, not rejected claims" do
      expect(subject.unverified_in_progress_count).to eq(1)
    end

    it "counts not started unverified, not rejected claims" do
      expect(subject.unverified_not_started_count).to eq(2)
    end

    it "counts all unverified, not rejected claims" do
      expect(subject.unverified_overall_count).to eq(3)
    end
  end

  describe "#amount" do
    context "when no claims" do
      it "returns zero" do
        expect(subject.amount).to be_zero
      end
    end

    # `approved` joins both eligibilities and decisions, so summing over it
    # directly counts a claim once per matching decision row. A validation
    # normally prevents a second active approved decision, but nothing at the
    # database level does — hence the subquery in #approved_amount.
    context "when a claim somehow has two active approved decisions" do
      it "counts the award once" do
        eligibility = create(
          :further_education_payments_eligibility,
          :provider_verification_completed,
          school: provider.school
        )

        claim = create(
          :claim,
          :further_education,
          :approved,
          eligibility:,
          academic_year: journey_configuration.current_academic_year
        )

        Decision.new(
          claim: claim,
          approved: true,
          created_by: create(:dfe_signin_user)
        ).save(validate: false)

        expect(claim.decisions.active.approved.count).to eq(2)
        expect(subject.amount).to eql(claim.award_amount)
      end
    end

    it "returns total approved award amount" do
      claims = 10.times.map do
        eligibility = create(
          :further_education_payments_eligibility,
          :provider_verification_completed,
          school: provider.school
        )

        create(
          :claim,
          :further_education,
          :approved,
          eligibility:,
          academic_year: journey_configuration.current_academic_year
        )
      end

      expect(subject.amount).to eql(claims.sum { |c| c.award_amount }.to_i)
    end

    context "when there are confirmed topups" do
      it "includes them" do
        eligibility = create(
          :further_education_payments_eligibility,
          :provider_verification_completed,
          school: provider.school
        )

        claim = create(
          :claim,
          :further_education,
          :approved,
          eligibility:,
          academic_year: journey_configuration.current_academic_year
        )

        payment = create(
          :payment,
          :confirmed,
          claims: [claim]
        )

        topup = create(
          :topup,
          claim:,
          payment:
        )

        expected = claim.award_amount + topup.award_amount
        expect(subject.amount).to eql(expected)
      end
    end
  end
end
