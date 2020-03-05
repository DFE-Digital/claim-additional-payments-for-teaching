require "rails_helper"

RSpec.feature "Choosing subjects taught during Teacher Student Loan Repayments claims" do
  include StudentLoansHelper
  before do
    start_student_loans_claim
    choose_school schools(:penistone_grammar_school)
  end

  context "with JS enabled", js: true do
    scenario "checks subjects and then chooses not applicable" do
      check "Biology"
      check "Physics"

      expect(page).to have_checked_field("eligible_subjects_biology_taught", visible: false)
      expect(page).to have_checked_field("eligible_subjects_physics_taught", visible: false)

      choose I18n.t("student_loans.questions.eligible_subjects.none_taught")

      expect(page).to have_checked_field("claim_eligibility_attributes_taught_eligible_subjects_false", visible: false)

      expect(page).to_not have_checked_field("eligible_subjects_biology_taught", visible: false)
      expect(page).to_not have_checked_field("eligible_subjects_physics_taught", visible: false)

      click_on "Continue"

      expect(page).to have_text("You did not select an eligible subject")
      expect(page).to have_text("You can only get this payment if you taught one or more of the following subjects between #{StudentLoans.current_financial_year}:")
    end

    scenario "checks not applicable and then chooses a subject" do
      choose I18n.t("student_loans.questions.eligible_subjects.none_taught")

      expect(page).to have_checked_field("claim_eligibility_attributes_taught_eligible_subjects_false", visible: false)

      check "Biology"

      expect(page).to have_checked_field("eligible_subjects_biology_taught", visible: false)
      expect(page).to_not have_checked_field("claim_eligibility_attributes_taught_eligible_subjects_false", visible: false)

      click_on "Continue"

      choose "Yes, at Penistone Grammar School"
      click_on "Continue"

      expect(page).to have_text(leadership_position_question)
    end
  end

  context "with JS disabled" do
    scenario "checks subjects and then chooses not applicable" do
      check "Biology"
      check "Physics"

      choose I18n.t("student_loans.questions.eligible_subjects.none_taught")
      click_on "Continue"

      expect(page).to have_text("You did not select an eligible subject")
      expect(page).to have_text("You can only get this payment if you taught one or more of the following subjects between #{StudentLoans.current_financial_year}:")
    end

    scenario "checks not applicable and then chooses a subject" do
      choose I18n.t("student_loans.questions.eligible_subjects.none_taught")

      check "Biology"
      click_on "Continue"

      expect(page).to have_text("You did not select an eligible subject")
      expect(page).to have_text("You can only get this payment if you taught one or more of the following subjects between #{StudentLoans.current_financial_year}:")
    end
  end
end
