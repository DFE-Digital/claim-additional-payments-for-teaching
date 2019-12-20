require "rails_helper"

RSpec.feature "DQT Report request" do
  scenario "Service operator can download CSV for the Database of Qualified Teachers report request" do
    sign_in_to_admin_with_role(DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE)

    claims = create_list(:claim, 3, :submitted)

    click_on "View claims"

    click_on "Download DQT report request file"

    expect(page.response_headers["Content-Type"]).to eq("text/csv")

    csv = CSV.parse(body, headers: true)

    expect(csv.count).to eq(3)
    expect(csv[2].fields("Claim reference")).to include(claims.last.reference)
  end
end
