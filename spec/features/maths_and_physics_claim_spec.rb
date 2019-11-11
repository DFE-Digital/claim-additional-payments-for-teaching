require "rails_helper"

RSpec.feature "Maths & Physics claims" do
  [true, false].each do |javascript_enabled|
    js_status = javascript_enabled ? "enabled" : "disabled"
    scenario "Teacher claims for Maths & Physics payment with JavaScript #{js_status}", js: javascript_enabled do
      visit "maths-and-physics/start"

      expect(page).to have_text "Claim a payment for teaching maths or physics"
    end
  end
end
