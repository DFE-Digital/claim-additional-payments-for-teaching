require "rails_helper"

RSpec.feature "Maths & Physics claims" do
  [true, false].each do |javascript_enabled|
    js_status = javascript_enabled ? "enabled" : "disabled"
    scenario "Teacher claims for Maths & Physics payment with JavaScript #{js_status}", js: javascript_enabled do
      visit "maths-and-physics/start"
      expect(page).to have_text "Claim a payment for teaching maths or physics"

      click_on "Start"
      expect(page).to have_text(I18n.t("maths_and_physics.questions.teaching_maths_or_physics"))

      choose "Yes"
      click_on "Continue"

      claim = Claim.order(:created_at).last
      eligibility = claim.eligibility

      expect(eligibility.teaching_maths_or_physics).to eql true
      expect(page).to have_text("You are eligible to claim a payment for teaching maths or physics")
    end
  end

  scenario "A teacher is ineligible for Maths & Physics" do
    visit new_claim_path(MathsAndPhysics.routing_name)

    expect(page).to have_text(I18n.t("maths_and_physics.questions.teaching_maths_or_physics"))

    choose "No"
    click_on "Continue"

    expect(page).to have_text("You’re not eligible for this payment")
    expect(page).to have_text("You can only get this payment if you teach maths or physics")
  end
end
