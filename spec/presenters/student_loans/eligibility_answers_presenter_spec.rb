require "rails_helper"

RSpec.describe StudentLoans::EligibilityAnswersPresenter, type: :model do
  let(:school) { schools(:penistone_grammar_school) }
  let(:eligibility_attributes) do
    {
      qts_award_year: "on_or_after_september_2013",
      claim_school: school,
      current_school: school,
      had_leadership_position: true,
      mostly_performed_leadership_duties: false,
      student_loan_repayment_amount: 1987.65,
    }.merge(subject_attributes)
  end
  let(:subject_attributes) { {chemistry_taught: true, physics_taught: true} }
  let(:eligibility) do
    build(
      :student_loans_eligibility,
      eligibility_attributes
    )
  end
  subject(:presenter) { described_class.new(eligibility) }

  it "returns an array of questions, answers, and slugs for displaying to the user for review" do
    expected_answers = [
      [I18n.t("questions.qts_award_year"), "On or after 1 September 2013", "qts-year"],
      [I18n.t("student_loans.questions.claim_school"), school.name, "claim-school"],
      [I18n.t("questions.current_school"), school.name, "still-teaching"],
      [I18n.t("student_loans.questions.subjects_taught", school: school.name), "Chemistry and Physics", "subjects-taught"],
      [I18n.t("student_loans.questions.leadership_position"), "Yes", "leadership-position"],
      [I18n.t("student_loans.questions.mostly_performed_leadership_duties"), "No", "mostly-performed-leadership-duties"],
    ]

    expect(presenter.answers).to eq expected_answers
  end

  it "excludes questions skipped from the flow" do
    eligibility.had_leadership_position = false
    expect(presenter.answers).to_not include([I18n.t("student_loans.questions.mostly_performed_leadership_duties"), "Yes", "mostly-performed-leadership-duties"])
    expect(presenter.answers).to_not include([I18n.t("student_loans.questions.mostly_performed_leadership_duties"), "No", "mostly-performed-leadership-duties"])
  end

  context "with three subjects taught" do
    let(:subject_attributes) { {chemistry_taught: true, physics_taught: true, biology_taught: true} }

    it "separates the subjects with commas and a final 'and'" do
      expect(presenter.answers[3][1]).to eq("Biology, Chemistry and Physics")
    end
  end
end
