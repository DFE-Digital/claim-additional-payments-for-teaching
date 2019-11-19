require "rails_helper"

RSpec.feature "Ineligible Maths and Physics claims" do
  scenario "not teaching maths or physics" do
    visit new_claim_path(MathsAndPhysics.routing_name)
    choose "No"
    click_on "Continue"
    claim = Claim.order(:created_at).last

    expect(claim.eligibility.teaching_maths_or_physics).to eql false
    expect(page).to have_text("You’re not eligible")
    expect(page).to have_text("You can only get this payment if you teach maths or physics.")
  end

  scenario "chooses an ineligible current school" do
    visit new_claim_path(MathsAndPhysics.routing_name)
    choose "Yes"
    click_on "Continue"

    choose_school schools(:hampstead_school)
    claim = Claim.order(:created_at).last

    expect(claim.eligibility.reload.current_school).to eq schools(:hampstead_school)
    expect(page).to have_text("This school is not eligible")
    expect(page).to have_text("You can only get this payment if you are employed to teach at an eligible state-funded secondary school.")
  end
end
