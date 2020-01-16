require "rails_helper"

RSpec.feature "Payroll" do
  let(:user) { create(:dfe_signin_user) }
  let!(:dataset_post_stub) { stub_geckoboard_dataset_update("claims.paid.test") }

  scenario "Service operator creates a payroll run" do
    sign_in_to_admin_with_role(DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE, user.dfe_sign_in_id)

    click_on "Payroll"

    create(:claim, :approved, policy: MathsAndPhysics)
    create(:claim, :approved, policy: StudentLoans)
    create(:claim, :approved, policy: StudentLoans)

    month_name = Date.today.strftime("%B")

    click_on "Run #{month_name} payroll"

    expect(page).to have_content("Approved claims 3")
    expect(page).to have_content("Total award amount £4,000")

    click_on "Confirm and submit"

    payroll_run = PayrollRun.order(:created_at).last

    expect(page).to have_content("Approved claims 3")
    expect(page).to have_content("Created by #{user.full_name}")
    expect(page).to have_content("Total award amount £4,000")
    expect(page).to have_content("Payroll run created")
    expect(page).to have_field("payroll_run_download_link", with: new_admin_payroll_run_download_url(payroll_run))
  end

  context "when a payroll run already exists for the month" do
    scenario "Service operator cannot create a new payroll run" do
      create(:payroll_run, claims_counts: {StudentLoans => 2}, created_at: 5.minutes.ago)
      sign_in_to_admin_with_role(DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE)

      visit admin_payroll_runs_path

      expect(page).not_to have_link("Prepare payroll")
    end
  end

  scenario "Any claims approved in the meantime are not included" do
    sign_in_to_admin_with_role(DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE)

    click_on "Payroll"

    expected_claims = create_list(:claim, 3, :approved)

    month_name = Date.today.strftime("%B")
    click_on "Run #{month_name} payroll"

    create_list(:claim, 3, :approved)

    click_on "Confirm and submit"

    expect(page).to have_content("Approved claims 3")

    payroll_run = PayrollRun.order(:created_at).last
    expect(payroll_run.claims).to match_array(expected_claims)
  end

  scenario "Service operator can view a list of previous payroll runs" do
    sign_in_to_admin_with_role(DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE)

    first_payroll_run = create(:payroll_run, created_at: Time.zone.now - 1.month)
    last_payroll_run = create(:payroll_run, created_at: Time.zone.now)

    click_on "Payroll"

    expect(page).to have_content("Payroll")

    expect(page).to have_content(I18n.l(first_payroll_run.created_at.to_date))
    expect(page).to have_content(I18n.l(last_payroll_run.created_at.to_date))

    expect(page).to have_link "View", href: admin_payroll_run_path(first_payroll_run)
    expect(page).to have_link "View", href: admin_payroll_run_path(last_payroll_run)
  end

  scenario "Service operator can view a payroll run" do
    sign_in_to_admin_with_role(DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE)

    payroll_run = create(:payroll_run, created_at: Time.zone.now)

    click_on "Payroll"
    click_on "View #{payroll_run.created_at.strftime("%B")} payroll run"

    expect(page).to have_content("Created by #{payroll_run.created_by.full_name}")
    expect(page).to have_content payroll_run.claims.count
    expect(page).to have_content "Downloaded No"
    expect(page).to have_field("payroll_run_download_link", with: new_admin_payroll_run_download_url(payroll_run))
  end

  scenario "Service operator can upload a Payment Confirmation Report against a payroll run" do
    sign_in_to_admin_with_role(DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE, "uploader-user-id")

    payroll_run = create(:payroll_run, claims_counts: {StudentLoans => 2})

    click_on "Payroll"

    click_on "Upload"

    expect(page).to have_content("Upload Payment Confirmation Report")

    csv = <<~CSV
      Payroll Reference,Gross Value,Payment ID,NI,Employers NI,Student Loans,Tax,Net Pay
      DFE00001,487.48,#{payroll_run.payments[0].id},33.9,38.98,0,89.6,325
      DFE00002,904.15,#{payroll_run.payments[1].id},77.84,89.51,40,162.8,534
    CSV

    file = Tempfile.new
    file.write(csv)
    file.rewind

    attach_file("Upload a Payment Confirmation Report CSV file", file.path)
    perform_enqueued_jobs { click_on "Upload file" }

    expect(page).to have_content("Payment Confirmation Report successfully uploaded")

    expect(page.find("table")).to have_content("Uploaded")

    expect(payroll_run.reload.confirmation_report_uploaded_by).to eq("uploader-user-id")
    expect(payroll_run.payments[0].reload.gross_value).to eq("487.48".to_d)

    expect(ActionMailer::Base.deliveries.count).to eq(2)

    subjects = ActionMailer::Base.deliveries.map { |delivery| delivery.subject }
    addressees = ActionMailer::Base.deliveries.map { |delivery| delivery.to }

    expect(addressees).to match_array([
      [payroll_run.claims[0].email_address],
      [payroll_run.claims[1].email_address],
    ])

    expect(subjects).to match_array([
      "We’re paying your claim to get back your student loan repayments, reference number: #{payroll_run.claims[0].reference}",
      "We’re paying your claim to get back your student loan repayments, reference number: #{payroll_run.claims[1].reference}",
    ])

    expect(dataset_post_stub).to have_been_requested.once
  end
end
