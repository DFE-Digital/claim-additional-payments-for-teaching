require "rails_helper"

RSpec.describe StudentLoans::EligibilityAnswersPresenter, type: :model do
  include StudentLoansHelper

  let(:subject_attributes) { {chemistry_taught: true, physics_taught: true} }
  let(:eligibility) { claim.eligibility }
  let(:claim) { build(:claim, eligibility: build(:student_loans_eligibility, :eligible, subject_attributes), qualifications_details_check:) }
  let(:qualifications_details_check) { false }

  subject(:presenter) { described_class.new(eligibility) }

  it "returns an array of questions, answers, and slugs for displaying to the user for review" do
    create(:journey_configuration, :student_loans)
    expected_answers = [
      [I18n.t("student_loans.questions.qts_award_year"), "Between the start of the 2013 to 2014 academic year and the end of the 2020 to 2021 academic year", "qts-year"],
      [claim_school_question, eligibility.claim_school.name, "claim-school"],
      [I18n.t("questions.current_school"), eligibility.current_school.name, "still-teaching"],
      [subjects_taught_question(school_name: eligibility.current_school.name), "Chemistry and Physics", "subjects-taught"],
      [leadership_position_question, "Yes", "leadership-position"],
      [mostly_performed_leadership_duties_question, "No", "mostly-performed-leadership-duties"]
    ]

    expect(presenter.answers).to eq expected_answers
  end

  it "changes the answer for the QTS question based on the answer and the claim's academic year" do
    claim.academic_year = "2027/2028"

    qts_answer = presenter.answers[0][1]
    expect(qts_answer).to eq("Between the start of the 2016 to 2017 academic year and the end of the 2020 to 2021 academic year")

    eligibility.qts_award_year = :before_cut_off_date
    qts_answer = presenter.answers[0][1]
    expect(qts_answer).to eq("A different academic year")
  end

  it "excludes questions skipped from the flow" do
    eligibility.had_leadership_position = false
    expect(presenter.answers).to_not include([mostly_performed_leadership_duties_question, "Yes", "mostly-performed-leadership-duties"])
    expect(presenter.answers).to_not include([mostly_performed_leadership_duties_question, "No", "mostly-performed-leadership-duties"])
  end

  context "with three subjects taught" do
    let(:subject_attributes) { {chemistry_taught: true, physics_taught: true, biology_taught: true} }

    it "separates the subjects with commas and a final 'and'" do
      expect(presenter.answers[3][1]).to eq("Biology, Chemistry and Physics")
    end
  end

  context "qualifications retrieved from DQT" do
    let(:qualifications_details_check) { true }

    it "removes the QTS question" do
      expect(presenter.answers).not_to include([I18n.t("student_loans.questions.qts_award_year"), "Between the start of the 2013 to 2014 academic year and the end of the 2020 to 2021 academic year", "qts-year"])
    end
  end
end
