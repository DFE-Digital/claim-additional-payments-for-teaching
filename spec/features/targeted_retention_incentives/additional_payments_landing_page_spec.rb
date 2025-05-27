require "rails_helper"

RSpec.describe "Additional Payments Landing Page" do
  before do
    create(:journey_configuration, :targeted_retention_incentive_payments)
  end

  it "redirects to the TRI journey" do
    visit "/additional-payments/landing-page"

    expect(page).to(
      have_current_path("/targeted-retention-incentive-payments/landing-page")
    )
  end
end
