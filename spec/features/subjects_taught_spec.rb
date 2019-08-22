require "rails_helper"

RSpec.feature "Choosing subjects taught during Teacher Student Loan Repayments claims" do
  before do
    start_claim
    visit claim_path("subjects-taught")
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

      expect(page).to have_text("You’re not eligible")
      expect(page).to have_text("You must have been teaching an eligible subject.")
    end

    scenario "checks not applicable and then chooses a subject" do
      choose I18n.t("student_loans.questions.eligible_subjects.none_taught")

      expect(page).to have_checked_field("claim_eligibility_attributes_taught_eligible_subjects_false", visible: false)

      check "Biology"

      expect(page).to have_checked_field("eligible_subjects_biology_taught", visible: false)
      expect(page).to_not have_checked_field("claim_eligibility_attributes_taught_eligible_subjects_false", visible: false)

      click_on "Continue"

      choose "Yes"
      click_on "Continue"

      expect(page).to have_text(I18n.t("student_loans.questions.mostly_performed_leadership_duties"))
    end
  end

  context "with JS disabled" do
    scenario "checks subjects and then chooses not applicable" do
      check "Biology"
      check "Physics"

      choose I18n.t("student_loans.questions.eligible_subjects.none_taught")
      click_on "Continue"

      expect(page).to have_text("You’re not eligible")
      expect(page).to have_text("You must have been teaching an eligible subject.")
    end

    scenario "checks not applicable and then chooses a subject" do
      choose I18n.t("student_loans.questions.eligible_subjects.none_taught")

      check "Biology"
      click_on "Continue"

      expect(page).to have_text("You’re not eligible")
      expect(page).to have_text("You must have been teaching an eligible subject.")
    end
  end
end
