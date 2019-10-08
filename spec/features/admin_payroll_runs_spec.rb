require "rails_helper"

RSpec.feature "Payroll" do
  scenario "Service operator creates a payroll run" do
    sign_in_to_admin_with_role(AdminSession::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE)

    click_on "Payroll"

    create_list(:claim, 3, :approved)
    create_list(:claim, 1, :submitted)

    click_on "Prepare payroll"

    expect(page).to have_content("Approved claims 3")
    expect(page).to have_content("Total award amount £3,000")

    click_on "Create payroll file"

    expect(page).to have_content("Approved claims 3")
    expect(page).to have_content("Total award amount £3,000")

    click_on "Download file"

    expect(page.response_headers["Content-Type"]).to eq("text/csv")

    csv = CSV.parse(body, headers: true)
    expect(csv.count).to eq(3)
  end

  scenario "Any claims approved in the meantime are not included" do
    sign_in_to_admin_with_role(AdminSession::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE)

    click_on "Payroll"

    expected_claims = create_list(:claim, 3, :approved)

    click_on "Prepare payroll"

    create_list(:claim, 3, :approved)

    click_on "Create payroll file"

    expect(page).to have_content("Approved claims 3")

    payroll_run = PayrollRun.order(:created_at).last
    expect(payroll_run.claims).to match_array(expected_claims)
  end

  scenario "Service operator can view a list of previous payroll runs" do
    sign_in_to_admin_with_role(AdminSession::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE)

    first_payroll_run = create(:payroll_run, created_at: Time.zone.now - 1.week)
    last_payroll_run = create(:payroll_run, created_at: Time.zone.now)

    click_on "Payroll"

    expect(page).to have_content("Payroll")

    expect(page).to have_content(I18n.l(first_payroll_run.created_at.to_date))
    expect(page).to have_content(I18n.l(last_payroll_run.created_at.to_date))
  end
end
