require "rails_helper"

RSpec.feature "Switching policies" do
  include StudentLoansHelper

  before do
    create(:journey_configuration, :student_loans)
    create(:journey_configuration, :early_career_payments)
    create(:journey_configuration, :get_a_teacher_relocation_payment)
  end

  context "swtiching from student loans to additional payments" do
    before do
      start_student_loans_claim
      visit new_claim_path("additional-payments")
    end

    scenario "a user can switch to a different policy after starting a claim on another" do
      expect(page.title).to have_text(I18n.t("additional_payments.journey_name"))
      expect(page.find("header")).to have_text(I18n.t("additional_payments.journey_name"))

      choose "Start a new eligibility check"
      click_on "Continue"

      expect(page).to have_text("You can sign in or set up a DfE Identity account to make it easier to claim additional payments.")
    end

    scenario "a user can choose to continue their claim" do
      choose "Continue with the eligibility check that you have already started"
      click_on "Continue"

      expect(page).to have_text(claim_school_question)
    end
  end

  context "switching from additional payments to get a teacher relocation payment" do
    before do
      school = create(:school, :combined_journey_eligibile_for_all)

      visit new_claim_path("additional-payments")

      skip_tid

      choose_school school

      visit new_claim_path("get-a-teacher-relocation-payment")
    end

    scenario "a user can switch to a different policy after starting a claim on another" do
      expect(page.title).to have_text(
        I18n.t("get_a_teacher_relocation_payment.journey_name")
      )

      expect(page.find("header")).to(
        have_text(I18n.t("get_a_teacher_relocation_payment.journey_name"))
      )

      choose "Start a new eligibility check"

      click_on "Continue"

      expect(page.title).to include(
        "What is your employment status? — Get a teacher relocation payment"
      )
    end

    scenario "a user can choose to continue their claim" do
      choose "Continue with the eligibility check that you have already started"
      click_on "Continue"

      expect(page.title).to include("Claim additional payments for teaching")
    end
  end

  context "Switching from teacher relocation to additional payments" do
    before do
      visit new_claim_path("get-a-teacher-relocation-payment")

      # FIXME RL as of writing this test, the journey only has one page "check
      # your answers", once the real first page of the journey is added this
      # test will need to be updated to select an option on that page
      click_on "Continue"

      visit new_claim_path("additional-payments")
    end

    scenario "a user can switch to a different policy after starting a claim on another" do
      expect(page).to have_content "You have already started an eligibility check"

      expect(page).to have_content "You can only have one eligibility check in progress at any time."

      choose "Start a new eligibility check"

      click_on "Continue"
    end
  end

  context "Switching to the same journey" do
    scenario "a user can switch to the same journey after starting a claim on that journey" do
      school = create(:school, :combined_journey_eligibile_for_all)

      visit new_claim_path("additional-payments")

      skip_tid

      choose_school school

      expect(page).to have_text(
        "Are you currently teaching as a qualified teacher?"
      )

      visit new_claim_path("additional-payments")

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
    visit new_claim_path("additional-payments")

    click_on "Continue"

    expect(page).to have_text("Select if you want to continue a previous eligibility check or start a new one")
  end
end
