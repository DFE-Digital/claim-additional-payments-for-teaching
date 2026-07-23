require "rails_helper"

RSpec.feature "Further education payments" do
  include ActionView::Helpers::NumberHelper

  let(:school) { create(:school, :fe_eligible) }
  let(:college) { school }
  let(:expected_award_amount) { college.eligible_fe_provider.max_award_amount }

  scenario "visiting impermissible slug redirects back to last permissible slug" do
    when_further_education_payments_journey_configuration_exists

    visit landing_page_path(Journeys::FurtherEducationPayments.routing_name)
    click_link "Start now"

    expect(page).to have_content("Do you have a")
    choose "No"
    click_button "Continue"

    expect(page).to have_content("Did you apply for a")
    choose "No"
    click_button "Continue"

    expect(page).to have_content("Make a claim for a targeted retention incentive payment for further education")
    click_button "Start eligibility check"

    expect(page).to have_content("Are you a member of staff with the responsibilities of a teacher?")

    visit claim_path(Journeys::FurtherEducationPayments.routing_name, slug: "address")

    expect(page).to have_content("Are you a member of staff with the responsibilities of a teacher?")
  end

  def and_college_exists
    school
  end
end
