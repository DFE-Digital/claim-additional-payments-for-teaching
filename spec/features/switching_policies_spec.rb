require "rails_helper"

RSpec.feature "Switching policies" do
  before do
    start_student_loans_claim
    visit new_claim_path(MathsAndPhysics.routing_name)
  end

  scenario "a user can switch to a different policy after starting a claim on another" do
    expect(page.title).to have_text(I18n.t("maths_and_physics.policy_name"))
    expect(page.find("header")).to have_text(I18n.t("maths_and_physics.policy_name"))

    click_on "Start claim for a payment for teaching maths or physics"

    expect(page).to have_text(I18n.t("maths_and_physics.questions.teaching_maths_or_physics"))
  end

  scenario "a user can choose to continue their claim" do
    click_on "Finish claim in progress"

    expect(page).to have_text(I18n.t("student_loans.questions.claim_school"))
  end
end
