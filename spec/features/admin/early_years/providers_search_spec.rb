require "rails_helper"

RSpec.describe "Providers Search" do
  before do
    journey_config = create(
      :journey_configuration,
      :early_years_payment_provider_authenticated
    )

    provider_1 = create(
      :eligible_ey_provider,
      nursery_name: "Happy Kids Nursery",
      primary_key_contact_email_address: "hkn@example.com",
      max_claims: 5
    )

    2.times do |i|
      create(
        :claim,
        policy: Policies::EarlyYearsPayments,
        eligibility_attributes: {
          nursery_urn: provider_1.urn
        },
        academic_year: journey_config.current_academic_year,
        reference: "CLAIM#{i + 1}"
      )
    end

    _provider_2 = create(
      :eligible_ey_provider,
      nursery_name: "Sunny Days Nursery",
      primary_key_contact_email_address: "sdn@example.com",
      max_claims: 10
    )
  end

  it "requires admin authentication" do
    visit admin_early_years_providers_path

    expect(page).to have_current_path("/admin/auth/sign-in")
  end

  it "shows provider claims" do
    sign_in_as_service_operator

    visit admin_early_years_providers_path

    within("tbody tr:first-of-type") do
      expect(page).to have_content("Happy Kids Nursery")
      expect(page).to have_content("hkn@example.com")
      expect(page).to have_content("5")
      expect(page).to have_content("2") # claims made
    end

    within("tbody tr:last-of-type") do
      expect(page).to have_content("Sunny Days Nursery")
      expect(page).to have_content("sdn@example.com")
      expect(page).to have_content("10")
      expect(page).to have_content("0") # claims made
    end
  end

  it "allows searching for providers by name or email" do
    sign_in_as_service_operator

    visit admin_early_years_providers_path

    fill_in(
      "Search by nursery name or primary contact email address",
      with: "Happy"
    )

    click_button "Search"

    expect(page).to have_content("Happy Kids Nursery")
    expect(page).not_to have_content("Sunny Days Nursery")

    fill_in(
      "Search by nursery name or primary contact email address",
      with: "sdn@example.com"
    )

    click_button "Search"

    expect(page).to have_content("Sunny Days Nursery")
    expect(page).not_to have_content("Happy Kids Nursery")
  end

  it "allows exporting the provider list as CSV" do
    sign_in_as_service_operator

    visit admin_early_years_providers_path

    click_link "Export CSV"

    expect(page.response_headers["Content-Type"]).to include("text/csv")
    expect(page).to have_content("Nursery Name,Primary Contact Email,Max Claims,Claims Submitted,Claim References")

    # TODO: CLAIM1, CLAIM2 ordering can be flaky
    expect(page).to have_content("Happy Kids Nursery,hkn@example.com,5,2,CLAIM1 CLAIM2")
    expect(page).to have_content("Sunny Days Nursery,sdn@example.com,10,0,")
  end
end
