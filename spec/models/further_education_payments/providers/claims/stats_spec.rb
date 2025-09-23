require "rails_helper"

RSpec.describe FurtherEducationPayments::Providers::Claims::Stats do
  let(:school) { create(:school) }
  let(:other_school) { create(:school) }

  subject { described_class.new(school:) }

  let!(:journey_configuration) do
    create(:journey_configuration, :further_education_payments)
  end

  describe "#rejected_count" do
    it "returns correct value" do
      eligibility = create(
        :further_education_payments_eligibility,
        :provider_verification_completed,
        school:
      )

      create(
        :claim,
        :further_education,
        :rejected,
        eligibility:,
        academic_year: journey_configuration.current_academic_year
      )

      expect(subject.rejected_count).to eql(1)
    end

    it "excludes claims from other schools" do
      eligibility = create(
        :further_education_payments_eligibility,
        :provider_verification_completed,
        school: other_school
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
        school:
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
    it "returns correct value" do
      eligibility = create(
        :further_education_payments_eligibility,
        :provider_verification_completed,
        school:
      )

      create(
        :claim,
        :further_education,
        :approved,
        eligibility:,
        academic_year: journey_configuration.current_academic_year
      )

      expect(subject.approved_count).to eql(1)
    end

    it "excludes claims from other schools" do
      eligibility = create(
        :further_education_payments_eligibility,
        :provider_verification_completed,
        school: other_school
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
        school:
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
        school:
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
        school: other_school
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
        school:
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
        school:
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
        school:
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

  describe "#amount_paid" do
    context "when no claims" do
      it "returns zero" do
        expect(subject.amount_paid).to be_zero
      end
    end

    context "when paid" do
      it "returns paid amount" do
        eligibility = create(
          :further_education_payments_eligibility,
          :provider_verification_completed,
          :with_award_amount,
          school:
        )

        claim = create(
          :claim,
          :further_education,
          :rejected,
          eligibility:,
          academic_year: journey_configuration.current_academic_year
        )

        create(
          :payment,
          :confirmed,
          claims: [claim]
        )

        expect(subject.amount_paid).to eql(eligibility.award_amount)
      end

      context "when payment not confirmed" do
        it "is not included" do
          eligibility = create(
            :further_education_payments_eligibility,
            :provider_verification_completed,
            :with_award_amount,
            school:
          )

          claim = create(
            :claim,
            :further_education,
            :rejected,
            eligibility:,
            academic_year: journey_configuration.current_academic_year
          )

          create(
            :payment,
            claims: [claim]
          )

          expect(subject.amount_paid).to be_zero
        end
      end

      context "when there are topups" do
        it "includes topups" do
          eligibility = create(
            :further_education_payments_eligibility,
            :provider_verification_completed,
            :with_award_amount,
            school:
          )

          claim = create(
            :claim,
            :further_education,
            :rejected,
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

          expected = eligibility.award_amount + topup.award_amount
          expect(subject.amount_paid).to eql(expected)
        end
      end
    end
  end
end
