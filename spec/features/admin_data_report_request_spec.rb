require "rails_helper"

RSpec.feature "Data report request" do
  scenario "Service operator can download an external data report request file" do
    sign_in_as_service_operator

    claims = create_list(:claim, 3, :submitted)

    click_on "View claims"

    click_on "Download report request file"

    expect(page.response_headers["Content-Type"]).to eq("text/csv")

    csv = CSV.parse(body, headers: true)

    expect(csv.count).to eq(3)
    expect(csv[2].fields("Claim reference")).to include(claims.last.reference)
    expect(csv[2].fields("Full name")).to include(claims.last.full_name)
  end
end
