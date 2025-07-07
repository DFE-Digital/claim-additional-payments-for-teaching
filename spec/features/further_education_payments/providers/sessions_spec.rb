require "rails_helper"

RSpec.describe "Provider session and authentication", feature_flag: :provider_dashboard do
  before do
    allow(DfESignIn).to receive(:bypass?).and_return(true)
  end

  scenario "when authed can visit auth walled areas", js: true do
    visit "/further_education_payments/providers/session/new"
    click_button "Start now"

    expect(page).to have_selector("h1", text: "Unverified claims")
    click_link "Verified claims"

    expect(page).to have_selector("h1", text: "Verified claims")
    click_link "Sign out"

    expect(page).to have_text "Sign in"

    visit "/further_education_payments/providers/claims"
    expect(page).to have_text "Sign in"

    visit "/further_education_payments/providers/verified-claims"
    expect(page).to have_text "Sign in"
  end
end
