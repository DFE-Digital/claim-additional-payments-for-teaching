require "rails_helper"

RSpec.feature "Choosing subjects taught during Teacher Student Loan Repayments claims" do
  before do
    start_tslr_claim
    visit claim_path("subjects-taught")
  end

  context "with JS enabled", js: true do
    scenario "checks subjects and then chooses not applicable" do
      check "eligible_subjects_biology_taught"
      check "eligible_subjects_physics_taught"

      expect(page).to have_checked_field("eligible_subjects_biology_taught", visible: false)
      expect(page).to have_checked_field("eligible_subjects_physics_taught", visible: false)

      choose I18n.t("tslr.questions.eligible_subjects.not_applicable")

      expect(page).to have_checked_field("tslr_claim_eligibility_attributes_mostly_teaching_eligible_subjects_false", visible: false)

      expect(page).to_not have_checked_field("eligible_subjects_biology_taught", visible: false)
      expect(page).to_not have_checked_field("eligible_subjects_physics_taught", visible: false)

      click_on "Continue"

      expect(page).to have_text("You’re not eligible")
      expect(page).to have_text("You must have spent at least half your time teaching an eligible subject.")
    end

    scenario "checks not applicable and then chooses a subject" do
      choose I18n.t("tslr.questions.eligible_subjects.not_applicable")

      expect(page).to have_checked_field("tslr_claim_eligibility_attributes_mostly_teaching_eligible_subjects_false", visible: false)

      check "eligible_subjects_biology_taught"

      expect(page).to have_checked_field("eligible_subjects_biology_taught", visible: false)
      expect(page).to_not have_checked_field("tslr_claim_eligibility_attributes_mostly_teaching_eligible_subjects_false", visible: false)

      click_on "Continue"

      expect(page).to have_text(I18n.t("tslr.questions.mostly_teaching_eligible_subjects", subjects: "Biology"))
    end
  end

  context "with JS disabled" do
    scenario "checks subjects and then chooses not applicable" do
      check "eligible_subjects_biology_taught"
      check "eligible_subjects_physics_taught"

      choose I18n.t("tslr.questions.eligible_subjects.not_applicable")
      click_on "Continue"

      expect(page).to have_text("You’re not eligible")
      expect(page).to have_text("You must have spent at least half your time teaching an eligible subject.")
    end

    scenario "checks not applicable and then chooses a subject" do
      choose I18n.t("tslr.questions.eligible_subjects.not_applicable")

      check "eligible_subjects_biology_taught"
      click_on "Continue"

      expect(page).to have_text("You’re not eligible")
      expect(page).to have_text("You must have spent at least half your time teaching an eligible subject.")
    end
  end
end
