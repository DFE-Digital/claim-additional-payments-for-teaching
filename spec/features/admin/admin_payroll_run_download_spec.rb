require "rails_helper"

RSpec.feature "Payroll run download" do
  scenario "User can download a payroll run file" do
    sign_in_to_admin_with_role(DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE)

    payroll_run = create(:payroll_run, claims_counts: {Policies::StudentLoans => 4, Policies::EarlyCareerPayments => 3, Policies::TargetedRetentionIncentivePayments => 2})

    visit new_admin_payroll_run_download_path(payroll_run)

    expect(page).to have_content "This month's payroll file is ready for processing."

    click_on "Download payroll file"

    click_on "Download #{payroll_run.created_at.strftime("%B")} payroll file"

    expect(page.response_headers["Content-Type"]).to eq("text/csv")

    csv = CSV.parse(body, headers: true)
    expect(csv.count).to eq(9)
  end
end
