require "rails_helper"

RSpec.feature "Data report request" do
  scenario "Service operator can download an external data report request file" do
    create(:journey_configuration, :student_loans)
    create(:journey_configuration, :additional_payments)

    sign_in_as_service_operator

    claims = [
      create(:claim, :submitted, policy: Policies::StudentLoans),
      create(:claim, :submitted, policy: Policies::EarlyCareerPayments),
      create(:claim, :submitted, policy: Policies::LevellingUpPremiumPayments),
      create(:claim, :submitted, :held, policy: Policies::LevellingUpPremiumPayments) # includes held claims
    ]

    claims.concat create_list(:claim, 100, :submitted) # Making sure CSV is not paginated at 50 claims/page

    create_list(:claim, 150, :approved) # Making sure CSV excludes approved claims in the download
    create_list(:claim, 4, :rejected) # Making sure CSV excludes rejected claims in the download

    click_on "View claims"
    click_on "Download report request file"

    expect(page.response_headers["Content-Type"]).to eq("text/csv")

    csv = CSV.parse(body, headers: true)

    # 4 claims + the 100 submitted claims
    expect(csv.count).to eq(104)

    csv.each_with_index do |row, i|
      claim = claims.detect { |c| c.reference == row["Claim reference"] }
      expect(claim).not_to be_nil
      expect(row["Teacher reference number"]).to eq(claim.eligibility.teacher_reference_number)
      expect(row["NINO"]).to eq(claim.national_insurance_number)
      expect(row["Full name"]).to eq(claim.full_name)
      expect(row["Email"]).to eq(claim.email_address)
      expect(row["Date of birth"]).to eq(claim.date_of_birth.to_s)
      expect(row["ITT subject"]).to eq(claim.eligibility.eligible_itt_subject)
      expect(row["Policy name"]).to eq(claim.policy.to_s)
    end
  end
end
