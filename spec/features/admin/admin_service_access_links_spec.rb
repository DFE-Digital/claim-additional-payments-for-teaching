require "rails_helper"

RSpec.describe "Admin service access links" do
  before do
    create(
      :journey_configuration,
      :further_education_payments,
      :closed,
      availability_message: "This service is closed for submissions"
    )

    allow(Reference).to receive(:new) { double(to_s: "ABCDEFG") }
  end

  it "allows an admin to create a service access code" do
    sign_in_as_service_admin

    visit "/admin"

    click_on "Manage services"

    click_on "Change Claim a targeted retention incentive payment for further education teachers"

    click_on "Generate a new service access link"

    link_field = find("#service_access_link")

    expect(link_field[:value]).to eq(
      landing_page_url(
        "further-education-payments",
        service_access_code: "ABCDEFG"
      )
    )
  end
end
