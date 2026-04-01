require "rails_helper"

RSpec.describe "Provider session and authentication", feature_flag: [:fe_provider_dashboard] do
  before do
    allow(DfeSignIn::Config).to receive(:instance).and_return(OpenStruct.new(bypass?: true))

    create(:journey_configuration, :further_education_payments)
    create(:eligible_fe_provider, :with_school, :with_dsi_bypass_ukprn)
  end

  scenario "when authed can visit auth walled areas", js: true do
    visit "/further-education-payments/providers/session/new"
    click_button "Start now"

    expect(page).to have_selector("h1", text: "Unverified claims")
    click_link "Verified claims"

    expect(page).to have_selector("h1", text: "Verified claims")
    click_link "Sign out"

    expect(page).to have_text "Sign in"

    visit "/further-education-payments/providers/claims"
    expect(page).to have_text "Sign in"

    visit "/further-education-payments/providers/verified-claims"
    expect(page).to have_text "Sign in"
  end

  scenario "when visiting the year one url when signed out" do
    visit "/further-education-payment-providers/landing-page"

    expect(page).to have_current_path(
      "/further-education-payments/providers/session/new"
    )
    expect(page).to have_text "Sign in"
  end

  scenario "when visiting the year one url when signed out" do
    visit "/further-education-payments/providers/session/new"
    click_button "Start now"

    visit "/further-education-payment-providers/landing-page"

    expect(page).to have_text "Unverified claims"
  end
end
