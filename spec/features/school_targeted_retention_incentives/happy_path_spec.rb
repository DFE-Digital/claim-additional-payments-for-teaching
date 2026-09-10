require "rails_helper"

RSpec.describe "new STRI journey", feature_flag: [:new_stri] do
  before do
    create(:journey_configuration, :targeted_retention_incentive_payments)
  end

  scenario "happy path" do
    visit landing_page_path(Journeys::SchoolTargetedRetentionIncentivePayments.routing_name)
    expect(page).to have_text "new stri landing page goes here"
  end
end
