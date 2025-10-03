require "rails_helper"

RSpec.describe Journeys::FurtherEducationPayments::SessionAnswers do
  subject { described_class.new(answers.attributes) }

  let(:school) { create(:school, :further_education, :fe_eligible) }

  describe "#calculate_award_amount" do
    context "when teaching over 20 hours per week" do
      let(:answers) do
        build(
          :further_education_payments_answers,
          school_id: school.id,
          teaching_hours_per_week: "more_than_20"
        )
      end

      it "returns max award amount" do
        expect(subject.calculate_award_amount).to eql(school.eligible_fe_provider.max_award_amount)
      end
    end

    context "when teaching over 12 hours per week" do
      let(:answers) do
        build(
          :further_education_payments_answers,
          school_id: school.id,
          teaching_hours_per_week: "more_than_12"
        )
      end

      it "returns max award amount" do
        expect(subject.calculate_award_amount).to eql(school.eligible_fe_provider.max_award_amount)
      end
    end

    context "when teaching between 2.5 and 12 hours per week" do
      let(:answers) do
        build(
          :further_education_payments_answers,
          school_id: school.id,
          teaching_hours_per_week: "between_2_5_and_12"
        )
      end

      it "returns lower award amount" do
        expect(subject.calculate_award_amount).to eql(school.eligible_fe_provider.lower_award_amount)
      end
    end

    context "when teaching less than 2.5 hours per week" do
      let(:answers) do
        build(
          :further_education_payments_answers,
          school_id: school.id,
          teaching_hours_per_week: "less_than_2_5"
        )
      end

      it "returns zero" do
        expect(subject.calculate_award_amount).to be_zero
      end
    end
  end

  describe "#claim_already_submitted_this_policy_year?" do
    subject do
      described_class.new(
        onelogin_uid: onelogin_uid
      ).claim_already_submitted_this_policy_year?
    end

    context "when no claims exist with a matching one login id" do
      let(:onelogin_uid) { "12345" }

      it { is_expected.to be false }
    end

    context "when a claim exists with a matching one login id" do
      before do
        create(
          :claim,
          policy: policy,
          onelogin_uid: onelogin_uid,
          academic_year: academic_year
        )
      end

      context "when the claim is from a different policy year" do
        let(:policy) { Policies::FurtherEducationPayments }
        let(:academic_year) { AcademicYear.previous }
        let(:onelogin_uid) { "12345" }

        it { is_expected.to be false }
      end

      context "when the claim is from the same policy year" do
        let(:academic_year) { AcademicYear.current }

        context "when the claim is for a different policy" do
          let(:policy) { Policies::EarlyYearsPayments }
          let(:onelogin_uid) { "12345" }

          it { is_expected.to be false }
        end

        context "when the claim is for FE" do
          context "when the one login id is nil" do
            let(:policy) { Policies::FurtherEducationPayments }
            let(:onelogin_uid) { nil }

            it { is_expected.to be false }
          end

          context "when the one login id is present" do
            let(:policy) { Policies::FurtherEducationPayments }
            let(:onelogin_uid) { "12345" }

            it { is_expected.to be true }
          end
        end
      end
    end
  end
end
