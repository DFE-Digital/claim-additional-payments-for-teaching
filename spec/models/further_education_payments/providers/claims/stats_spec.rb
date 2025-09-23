require "rails_helper"

RSpec.describe FurtherEducationPayments::Providers::Claims::Stats do
  let(:school) { create(:school) }
  let(:other_school) { create(:school) }

  subject { described_class.new(school:) }

  let!(:journey_configuration) do
    create(:journey_configuration, :further_education_payments)
  end

  describe "#rejected_count" do
    it "includes rejected and does need QA" do
      eligibility = create(
        :further_education_payments_eligibility,
        :provider_verification_completed,
        school:
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
        school:
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
        school:
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
    it "includes approved and does need QA" do
      eligibility = create(
        :further_education_payments_eligibility,
        :provider_verification_completed,
        school:
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
        school:
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
        school:
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

  describe "#approved_amount" do
    context "when no claims" do
      it "returns zero" do
        expect(subject.approved_amount).to be_zero
      end
    end

    it "returns total approved award amount" do
      claims = 10.times.map do
        eligibility = create(
          :further_education_payments_eligibility,
          :provider_verification_completed,
          :with_award_amount,
          school:
        )

        create(
          :claim,
          :further_education,
          :approved,
          eligibility:,
          academic_year: journey_configuration.current_academic_year
        )
      end

      expect(subject.approved_amount).to eql(claims.sum { |c| c.award_amount }.to_i)
    end
  end

  xdescribe "#amount_paid" do
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
