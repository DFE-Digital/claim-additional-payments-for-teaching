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

  scenario "Service operator can upload a Payment Confirmation Report against a payroll run" do
    sign_in_to_admin_with_role(AdminSession::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE, "uploader-user-id")

    payroll_run = create(:payroll_run)
    claims = create_list(:claim, 2, :approved, payroll_run: payroll_run)

    click_on "Payroll"

    click_on "Upload"

    expect(page).to have_content("Upload Payment Confirmation Report")

    csv = <<~CSV
      Payroll Reference,Gross Value,Claim ID,NI,Employers NI,Student Loans,Tax,Net Pay
      DFE00001,487.48,#{claims[0].reference},33.9,38.98,0,89.6,325
      DFE00002,904.15,#{claims[1].reference},77.84,89.51,40,162.8,534
    CSV

    file = Tempfile.new
    file.write(csv)
    file.rewind

    attach_file("Upload a Payment Confirmation Report CSV file", file.path)
    click_on "Upload file"

    expect(page).to have_content("Payment Confirmation Report successfully uploaded")

    expect(page.find("table")).to have_content("Uploaded")

    expect(payroll_run.reload.confirmation_report_uploaded_by).to eq("uploader-user-id")
    expect(claims[0].payment.reload.gross_value).to eq("487.48".to_d)
  end
end
