require "rails_helper"

RSpec.feature "Data report request" do
  scenario "Service operator can download an external data report request file" do
    sign_in_as_service_operator

    claims = [
      create(:claim, :submitted, policy: StudentLoans),
      create(:claim, :submitted, policy: MathsAndPhysics),
      create(:claim, :submitted, policy: EarlyCareerPayments)
    ]

    click_on "View claims"

    click_on "Download report request file"

    expect(page.response_headers["Content-Type"]).to eq("text/csv")

    csv = CSV.parse(body, headers: true)

    expect(csv.count).to eq(3)

    claims.each_with_index do |claim, index|
      expect(csv[index].fields("Claim reference")).to include(claim.reference)
      expect(csv[index].fields("Teacher reference number")).to include(claim.teacher_reference_number)
      expect(csv[index].fields("Full name")).to include(claim.full_name)
      expect(csv[index].fields("Email")).to include(claim.email_address)
      expect(csv[index].fields("Date of birth")).to include(claim.date_of_birth.to_s)
      expect(csv[index].fields("ITT subject")).to include(claim.eligibility.eligible_itt_subject)
      expect(csv[index].fields("Policy name")).to include(claim.policy.to_s)
    end
  end
end
