require "rails_helper"

RSpec.describe Journeys::FurtherEducationPayments::SessionAnswers do
  subject { described_class.new(answers.attributes) }

  let(:school) { create(:school, :further_education, :fe_eligible) }

  describe "#award_amount" do
    context "when teaching over 12 hours per week" do
      let(:answers) do
        build(
          :further_education_payments_answers,
          school_id: school.id,
          teaching_hours_per_week: "more_than_12"
        )
      end

      it "returns max award amount" do
        expect(subject.award_amount).to eql(school.eligible_fe_provider.max_award_amount)
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
        expect(subject.award_amount).to eql(school.eligible_fe_provider.lower_award_amount)
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
        expect(subject.award_amount).to be_zero
      end
    end
  end
end
