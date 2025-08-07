require "rails_helper"

RSpec.feature "Combined journey" do
  let!(:journey_configuration) { create(:journey_configuration, :targeted_retention_incentive_payments, teacher_id_enabled: false) }

  scenario "Teacher ID is disabled on the policy configuration" do
    visit landing_page_path(Journeys::TargetedRetentionIncentivePayments::ROUTING_NAME)

    # - Landing (start)
    expect(page).to have_text(
      "Find out if you are eligible for a targeted retention incentive payment"
    )
    click_on "Start now"

    # - Check eligibility intro
    expect(page).to have_text("Check you’re elegible for a targeted retention incentive payment")
    expect(page).not_to have_link "Back"
    click_on "Start eligibility check"

    # - Which school do you teach at
    expect(page).to have_text("Which school do you teach at?")
    expect(page.title).to have_text("Which school do you teach at?")
  end
end
