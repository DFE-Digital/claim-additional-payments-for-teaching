require "rails_helper"

RSpec.describe Policies::FurtherEducationPayments::PolicyEligibilityChecker do
  let(:answers) do
    build(
      :further_education_payments_answers,
      school_id: eligible_college.id
    )
  end

  let(:ineligible_college) { create(:school, :further_education) }
  let(:eligible_college) { create(:school, :further_education, :fe_eligible) }

  subject { described_class.new(answers: answers) }

  describe "#ineligible?, #ineligibility_reason" do
    context "when ineligible as lacking teaching responsibility" do
      let(:answers) do
        build(:further_education_payments_answers, teaching_responsibilities: false)
      end

      it "is ineligble as :lack_teaching_responsibilities" do
        expect(subject).to be_ineligible
        expect(subject.ineligibility_reason).to eql(:lack_teaching_responsibilities)
      end
    end

    context "when ineligible FE provider selected" do
      let(:answers) do
        build(
          :further_education_payments_answers,
          school_id: ineligible_college.id
        )
      end

      it "is ineligble as :lack_teaching_responsibilities" do
        expect(subject).to be_ineligible
        expect(subject.ineligibility_reason).to eql(:fe_provider)
      end
    end

    context "when have not taught for at least one academic term" do
      let(:answers) do
        build(
          :further_education_payments_answers,
          school_id: eligible_college.id,
          taught_at_least_one_term: false
        )
      end

      it "is ineligble as :must_teach_at_least_one_term" do
        expect(subject).to be_ineligible
        expect(subject.ineligibility_reason).to eql(:must_teach_at_least_one_term)
      end
    end

    context "when ineligible as lacking subjects taught" do
      let(:answers) do
        build(
          :further_education_payments_answers,
          school_id: eligible_college.id,
          subjects_taught: ["none"]
        )
      end

      it "is ineligble as :subject" do
        expect(subject).to be_ineligible
        expect(subject.ineligibility_reason).to eql(:subject)
      end
    end

    context "when all courses are ineligible" do
      let(:answers) do
        build(
          :further_education_payments_answers,
          school_id: eligible_college.id,
          subjects_taught: ["building_construction"],
          building_construction_courses: ["none"]
        )
      end

      it "is ineligble as :lack_teaching_responsibilities" do
        expect(subject).to be_ineligible
        expect(subject.ineligibility_reason).to eql(:courses)
      end
    end
  end
end
