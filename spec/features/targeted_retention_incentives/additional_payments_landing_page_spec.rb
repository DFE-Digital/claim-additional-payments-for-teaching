require "rails_helper"

RSpec.describe "Additional Payments Landing Page" do
  before do
    create(:journey_configuration, :additional_payments)
  end

  # We'll be redirecting these to TRI journey once removing additional payments
  # is complete.
  it "doesn't 404 external links to additional payments" do
    visit "/additional-payments/landing-page"

    expect(page).to have_content("Additional payments")
  end
end
