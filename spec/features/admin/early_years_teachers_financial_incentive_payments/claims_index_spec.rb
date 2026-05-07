require "rails_helper"

RSpec.describe "EYTFI claims displayed on index page" do
  it "viewing claims" do
    FeatureFlag.enable!(:eytfi_journey)

    sign_in_as_service_admin

    claim = create(
      :claim,
      :submitted,
      policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
      hmrc_bank_validation_succeeded: false,
      payroll_gender: "dont_know",
      onelogin_idv_at: DateTime.new(2026, 5, 1, 9, 30, 0),
      identity_confirmed_with_onelogin: true
    )

    visit admin_claims_path

    within "#filters" do
      select(
        "Early Years Teachers Financial Incentive Payments",
        from: "Policy"
      )

      click_on "Apply filters"
    end

    expect(page).to have_text(claim.reference)
  end
end
