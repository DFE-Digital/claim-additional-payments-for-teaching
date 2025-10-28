require "rails_helper"

RSpec.describe Journeys::TeacherStudentLoanReimbursement::AnswersPresenter, type: :model do
  include StudentLoansHelper

  let(:policy) { Policies::StudentLoans }
  let!(:journey_configuration) { create(:journey_configuration, :student_loans) }

  it_behaves_like "journey answers presenter"

  describe "#eligibility_answers" do
    let(:subject_attributes) { {chemistry_taught: true, physics_taught: true} }
    let(:qualifications_details_check) { false }

    let(:journey_session) do
      create(
        :student_loans_session,
        answers: attributes_for(
          :student_loans_answers,
          :with_claim_school,
          :with_current_school,
          :with_leadership_position,
          qualifications_details_check: qualifications_details_check
        ).merge(subject_attributes)
      )
    end

    subject(:answers) do
      described_class.new(journey_session).eligibility_answers
    end

    it "returns an array of questions, answers, and slugs for displaying to the user for review" do
      expected_answers = [
        [I18n.t("student_loans.forms.qts_year.questions.qts_award_year"), "Between the start of the #{(journey_configuration.current_academic_year - 11).to_s(:long)} academic year and the end of the 2020 to 2021 academic year", "qts-year"],
        [claim_school_question, journey_session.answers.claim_school.name, "claim-school"],
        [I18n.t("student_loans.forms.current_school.question"), journey_session.answers.current_school.name, "still-teaching"],
        [subjects_taught_question(school_name: journey_session.answers.claim_school.name), "Chemistry and Physics", "subjects-taught"],
        [leadership_position_question, "Yes", "leadership-position"],
        [mostly_performed_leadership_duties_question, "No", "mostly-performed-leadership-duties"]
      ]

      expect(answers).to eq expected_answers
    end

    it "changes the answer for the QTS question based on the answer and the claim's academic year" do
      journey_session.answers.academic_year = "2027/2028"

      qts_answer = answers[0][1]
      expect(qts_answer).to eq("Between the start of the 2016 to 2017 academic year and the end of the 2020 to 2021 academic year")
    end

    context "when the QTS year is before the cut off date" do
      it "does not show the academic year" do
        journey_session.answers.qts_award_year = :before_cut_off_date

        qts_answer = answers[0][1]
        expect(qts_answer).to eq("A different academic year")
      end
    end

    it "excludes questions skipped from the flow" do
      journey_session.answers.assign_attributes(had_leadership_position: false)
      expect(answers).to_not include([mostly_performed_leadership_duties_question, "Yes", "mostly-performed-leadership-duties"])
      expect(answers).to_not include([mostly_performed_leadership_duties_question, "No", "mostly-performed-leadership-duties"])
    end

    context "with three subjects taught" do
      let(:subject_attributes) { {chemistry_taught: true, physics_taught: true, biology_taught: true} }

      it "separates the subjects with commas and a final 'and'" do
        expect(answers[3][1]).to eq("Biology, Chemistry and Physics")
      end
    end

    context "qualifications retrieved from DQT" do
      let(:qualifications_details_check) { true }

      it "removes the QTS question" do
        expect(answers).not_to include([I18n.t("student_loans.forms.qts_year.questions.qts_award_year"), "Between the start of the 2013 to 2014 academic year and the end of the 2020 to 2021 academic year", "qts-year"])
      end
    end
  end
end
