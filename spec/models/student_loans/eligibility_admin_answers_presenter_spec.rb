require "rails_helper"

RSpec.describe StudentLoans::EligibilityAdminAnswersPresenter, type: :model do
  let(:school) { schools(:penistone_grammar_school) }
  let(:eligibility) do
    build(
      :student_loans_eligibility,
      qts_award_year: "on_or_after_september_2013",
      claim_school: school,
      current_school: school,
      chemistry_taught: true,
      physics_taught: true,
      had_leadership_position: true,
      mostly_performed_leadership_duties: false,
      student_loan_repayment_amount: 1987.65,
    )
  end
  subject(:presenter) { described_class.new(eligibility) }

  describe "#answers" do
    it "returns an array of questions and answers for displaying to approver" do
      expected_answers = [
        [I18n.t("admin.qts_award_year"), "On or after 1 September 2013"],
        [I18n.t("student_loans.admin.claim_school"), presenter.display_school(school)],
        [I18n.t("admin.current_school"), presenter.display_school(school)],
        [I18n.t("student_loans.admin.subjects_taught"), "Chemistry and Physics"],
        [I18n.t("student_loans.admin.had_leadership_position"), "Yes"],
        [I18n.t("student_loans.admin.mostly_performed_leadership_duties"), "No"],
      ]

      expect(presenter.answers).to eq expected_answers
    end

    it "excludes questions skipped from the flow" do
      eligibility.had_leadership_position = false
      expect(presenter.answers).to include([I18n.t("student_loans.admin.had_leadership_position"), "No"])
      expect(presenter.answers).to_not include([I18n.t("student_loans.admin.mostly_performed_leadership_duties"), "No"])
    end
  end
end
