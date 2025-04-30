require "rails_helper"

RSpec.feature "Choosing subjects taught during Teacher Student Loan Repayments claims" do
  include StudentLoansHelper

  let!(:school) { create(:school, :student_loans_eligible) }
  before do
    create(:journey_configuration, :student_loans)
    start_student_loans_claim
    choose_school school
  end

  context "with JS enabled", js: true, flaky: true do
    scenario "checks subjects and then chooses not applicable" do
      check "Biology"
      check "Physics"
      expect(page).to have_checked_field("Biology", visible: false)
      expect(page).to have_checked_field("Physics", visible: false)

      check I18n.t("student_loans.forms.subjects_taught.answers.none_taught")
      expect(page).to have_checked_field(I18n.t("student_loans.forms.subjects_taught.answers.none_taught"), visible: false)
      expect(page).to_not have_checked_field("Biology", visible: false)
      expect(page).to_not have_checked_field("Physics", visible: false)
      click_on "Continue"

      expect(page).to have_text("You did not select an eligible subject")
      expect(page).to have_text("You can only get this payment if you taught one or more of the following subjects between #{Policies::StudentLoans.current_financial_year}:")
    end

    scenario "checks not applicable and then chooses a subject" do
      check I18n.t("student_loans.forms.subjects_taught.answers.none_taught")
      expect(page).to have_checked_field(I18n.t("student_loans.forms.subjects_taught.answers.none_taught"), visible: false)
      check "Biology"
      expect(page).to have_checked_field("Biology", visible: false)
      expect(page).to_not have_checked_field(I18n.t("student_loans.forms.subjects_taught.answers.none_taught"), visible: false)
      click_on "Continue"

      choose "Yes, at #{school.name}"
      click_on "Continue"

      expect(page).to have_text(leadership_position_question)
    end
  end

  context "with JS disabled" do
    scenario "checks subjects and then chooses not applicable" do
      check "Biology"
      check "Physics"
      check I18n.t("student_loans.forms.subjects_taught.answers.none_taught")
      click_on "Continue"

      expect(page).to have_text("You did not select an eligible subject")
      expect(page).to have_text("You can only get this payment if you taught one or more of the following subjects between #{Policies::StudentLoans.current_financial_year}:")
    end

    scenario "checks not applicable and then chooses a subject" do
      check I18n.t("student_loans.forms.subjects_taught.answers.none_taught")

      check "Biology"
      click_on "Continue"

      expect(page).to have_text("You did not select an eligible subject")
      expect(page).to have_text("You can only get this payment if you taught one or more of the following subjects between #{Policies::StudentLoans.current_financial_year}:")
    end
  end
end
