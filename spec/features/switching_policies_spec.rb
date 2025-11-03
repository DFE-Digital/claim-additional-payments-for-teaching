require "rails_helper"

RSpec.feature "Switching policies" do
  include StudentLoansHelper

  before do
    create(:journey_configuration, :student_loans)
    create(:journey_configuration, :targeted_retention_incentive_payments)
    create(:journey_configuration, :get_a_teacher_relocation_payment)
  end

  context "swtiching to a different journey" do
    scenario "a user doesn't need to confirm they want to change journey" do
      start_student_loans_claim
      visit new_claim_path("targeted-retention-incentive-payments")

      expect(page.title).to have_text(I18n.t("targeted_retention_incentive_payments.journey_name"))
      expect(page.find(".govuk-service-navigation")).to have_text(I18n.t("targeted_retention_incentive_payments.journey_name"))

      expect(page).not_to have_text(
        "You have already started an eligibility check"
      )

      expect(page).not_to have_text(
        "You can only have one eligibility check in progress at any time."
      )
    end
  end

  context "Switching to the same journey" do
    scenario "a user can switch to the same journey after starting a claim on that journey" do
      school = create(:school, :targeted_retention_incentive_payments_eligible)

      visit new_claim_path("targeted-retention-incentive-payments")

      skip_tid

      choose_school school

      expect(page).to have_text(
        "Are you currently teaching as a qualified teacher?"
      )

      visit new_claim_path("targeted-retention-incentive-payments")

      expect(page).to(have_text(
        "You have already started an eligibility check"
      ))

      choose "Continue with the eligibility check that you have already started"

      click_on "Continue"

      expect(page).to have_text(
        "Are you currently teaching as a qualified teacher?"
      )
    end
  end

  scenario "a user does not select an option" do
    start_student_loans_claim

    visit new_claim_path("student-loans")

    click_on "Continue"

    expect(page).to have_text("Select if you want to continue a previous eligibility check or start a new one")
  end
end
