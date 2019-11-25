require "rails_helper"

RSpec.feature "Payroll run download" do
  scenario "User can download a payroll run file" do
    sign_in_to_admin_with_role(AdminSession::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE)

    payroll_run = create(:payroll_run, claims_counts: {StudentLoans: 2, MathsAndPhysics: 1})

    visit new_admin_payroll_run_download_path(payroll_run)

    expect(page).to have_content "This month's payroll file is ready for processing."
  end
end
