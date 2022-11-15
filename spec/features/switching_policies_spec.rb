require "rails_helper"

RSpec.feature "Switching policies" do
  include StudentLoansHelper

  before do
    create(:policy_configuration, :student_loans)
    create(:policy_configuration, :maths_and_physics)

    start_student_loans_claim
    visit new_claim_path(MathsAndPhysics.routing_name)
  end

  scenario "a user can switch to a different policy after starting a claim on another" do
    expect(page.title).to have_text(I18n.t("maths_and_physics.policy_name"))
    expect(page.find("header")).to have_text(I18n.t("maths_and_physics.policy_name"))

    choose "Yes, start claim for a payment for teaching maths or physics and lose my progress on my first claim"
    click_on "Submit"

    expect(page).to have_text(I18n.t("maths_and_physics.questions.teaching_maths_or_physics"))
  end

  scenario "a user can choose to continue their claim" do
    choose "No, finish the claim I have in progress"
    click_on "Submit"

    expect(page).to have_text(claim_school_question)
  end

  scenario "a user does not select an option" do
    click_on "Submit"

    expect(page).to have_text("Select yes if you want to start a claim for a payment for teaching maths or physics")
  end
end
