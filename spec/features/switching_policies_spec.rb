require "rails_helper"

RSpec.feature "Switching policies" do
  include StudentLoansHelper

  before do
    create(:journey_configuration, :student_loans)
    create(:journey_configuration, :early_career_payments)

    start_student_loans_claim
    visit new_claim_path("additional-payments")
  end

  scenario "a user can switch to a different policy after starting a claim on another" do
    expect(page.title).to have_text(I18n.t("additional_payments.journey_name"))
    expect(page.find("header")).to have_text(I18n.t("additional_payments.journey_name"))

    choose "Yes, start claim for an additional payment for teaching and lose my progress on my first claim"
    click_on "Submit"

    expect(page).to have_text("You can sign in or set up a DfE Identity account to make it easier to claim additional payments.")
  end

  scenario "a user can choose to continue their claim" do
    choose "No, finish the claim I have in progress"
    click_on "Submit"

    expect(page).to have_text(claim_school_question)
  end

  scenario "a user does not select an option" do
    click_on "Submit"

    expect(page).to have_text("Select yes if you want to start a claim for an additional payment for teaching")
  end
end
