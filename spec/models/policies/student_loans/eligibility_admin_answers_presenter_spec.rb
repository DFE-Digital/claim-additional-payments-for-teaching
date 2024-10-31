require "rails_helper"

RSpec.describe Policies::StudentLoans::EligibilityAdminAnswersPresenter, type: :model do
  let(:eligibility) { claim.eligibility }
  let(:claim) do
    build(:claim,
      academic_year: "2019/2020",
      eligibility: build(:student_loans_eligibility,
        :eligible,
        chemistry_taught: true,
        physics_taught: true,
        had_leadership_position: true,
        mostly_performed_leadership_duties: false,
        student_loan_repayment_amount: 1987.65))
  end
  subject(:presenter) { described_class.new(eligibility) }

  describe "#answers" do
    it "returns an array of questions and answers for displaying to approver" do
      expected_answers = [
        [I18n.t("admin.qts_award_year"), "Between the start of the 2013 to 2014 academic year and the end of the 2020 to 2021 academic year"],
        [I18n.t("student_loans.admin.claim_school"), presenter.display_school(eligibility.current_school)],
        [I18n.t("admin.current_school"), presenter.display_school(eligibility.current_school)],
        [I18n.t("student_loans.admin.subjects_taught"), "Chemistry and Physics"],
        [I18n.t("student_loans.admin.had_leadership_position"), "Yes"],
        [I18n.t("student_loans.admin.mostly_performed_leadership_duties"), "No"]
      ]

      expect(presenter.answers).to eq expected_answers
    end

    it "changes the answer for the QTS question based on the answer academic year the claim was made" do
      claim.academic_year = "2029/2030"

      expected_qts_answer = presenter.answers[0][1]
      expect(expected_qts_answer).to eq("Between the start of the 2018 to 2019 academic year and the end of the 2020 to 2021 academic year")
    end

    it "excludes questions skipped from the flow" do
      eligibility.had_leadership_position = false
      expect(presenter.answers).to include([I18n.t("student_loans.admin.had_leadership_position"), "No"])
      expect(presenter.answers).to_not include([I18n.t("student_loans.admin.mostly_performed_leadership_duties"), "No"])
    end
  end
end
