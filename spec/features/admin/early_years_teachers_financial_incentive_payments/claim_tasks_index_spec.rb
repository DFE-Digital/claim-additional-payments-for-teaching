require "rails_helper"

RSpec.describe "Task index page for EYTFI claims" do
  it "shows the list of tasks" do
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

    _duplicate_claim = create(
      :claim,
      :submitted,
      policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
      email_address: claim.email_address
    )

    ClaimVerifierJob.perform_now(claim)

    visit admin_claim_tasks_path(claim)

    expect(page).to have_text("1. Identity confirmation")
    expect(page).to have_text("2. Qualifications")
    expect(page).to have_text("3. Employment")
    expect(page).to have_text("4. Student loan plan")
    expect(page).to have_text("5. Payroll details")
    expect(page).to have_text("6. Payroll gender")
    expect(page).to have_text("7. Matching details")

    # Identity confirmation
    click_on "Confirm the claimant made the claim"

    expect(page).to have_text("Identity confirmed by One login on 1/5/2026")
  end
end
