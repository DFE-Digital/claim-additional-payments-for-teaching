require "rails_helper"

RSpec.feature "Payroll" do
  before { @signed_in_user = sign_in_as_service_operator }

  scenario "Service operator creates a payroll run" do
    click_on "Payroll"

    create(:claim, :approved, policy: MathsAndPhysics)
    create(:claim, :approved, policy: StudentLoans)
    create(:claim, :approved, policy: StudentLoans)
    create(:claim, :approved, policy: EarlyCareerPayments)
    create(:claim, :approved, policy: LevellingUpPremiumPayments)

    paid_lup_claim = nil
    travel_to 2.months.ago do
      lup_eligibility = create(:levelling_up_premium_payments_eligibility, :eligible, award_amount: 1500.0)
      paid_lup_claim = create(:claim, :approved, policy: LevellingUpPremiumPayments, eligibility: lup_eligibility)
      create(:payment, :with_figures, claims: [paid_lup_claim])
    end

    user = create(:dfe_signin_user)
    create(:topup, claim: paid_lup_claim, award_amount: 500, created_by: user)

    month_name = Date.today.strftime("%B")

    click_on "Run #{month_name} payroll"

    expect(page).to have_content("Approved claims 5")
    expect(page).to have_content("Top up payments 1")
    expect(page).to have_content("Total award amount £11,500.00")

    click_on "Confirm and submit"

    payroll_run = PayrollRun.order(:created_at).last

    expect(page).to have_content("Approved claims 5")
    expect(page).to have_content("Top ups 1")
    expect(page).to have_content("Created by #{@signed_in_user.full_name}")
    expect(page).to have_content("Total award amount £11,500.00")
    expect(page).to have_content("Payroll run created")
    expect(page).to have_field("payroll_run_download_link", with: new_admin_payroll_run_download_url(payroll_run))

    expect(page).to have_content("Student Loans 2 £2,000.00")
    expect(page).to have_content("Maths and Physics 1 £2,000.00")
    expect(page).to have_content("Early-Career Payments 1 £5,000.00")
    expect(page).to have_content("Levelling Up Premium Payments 1 £2,000.00")
    expect(page).to have_content("Levelling Up Premium Payments Top Ups 1 £500.00")
  end

  context "when a payroll run already exists for the month" do
    scenario "Service operator cannot create a new payroll run" do
      create(:payroll_run, claims_counts: {StudentLoans => 2}, created_at: 5.minutes.ago)

      visit admin_payroll_runs_path

      expect(page).not_to have_link("Prepare payroll")
    end
  end

  scenario "Any claims approved in the meantime are not included" do
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
    payroll_run = create(:payroll_run, claims_counts: {MathsAndPhysics => 1, StudentLoans => 1})

    click_on "Payroll"
    click_on "View #{payroll_run.created_at.strftime("%B")} payroll run"

    expect(page).to have_content("Created by #{payroll_run.created_by.full_name}")
    expect(page).to have_content payroll_run.claims.count
    expect(page).to have_content "Downloaded No"
    expect(page).to have_field("payroll_run_download_link", with: new_admin_payroll_run_download_url(payroll_run))

    expect(page).to have_content payroll_run.payments[0].id
    expect(page).to have_content payroll_run.payments[1].id

    expect(page).to have_link(href: remove_admin_payroll_run_payment_path(id: payroll_run.payments[0].id, payroll_run_id: payroll_run.id))
    expect(page).to have_link(href: remove_admin_payroll_run_payment_path(id: payroll_run.payments[1].id, payroll_run_id: payroll_run.id))
  end

  scenario "Service operator can remove a payment from a payroll run" do
    payroll_run = create(:payroll_run, claims_counts: {MathsAndPhysics => 1, StudentLoans => 1})
    payment_to_delete = payroll_run.payments.first
    claim_reference = payment_to_delete.claims.first.reference

    click_on "Payroll"
    click_on "View #{payroll_run.created_at.strftime("%B")} payroll run"

    find("a[href='#{remove_admin_payroll_run_payment_path(id: payment_to_delete.id, payroll_run_id: payroll_run.id)}']").click

    expect(page).to have_content("Are you sure you want to remove payment #{payment_to_delete.id} from the payroll run?")

    expect {
      click_on "Remove payment"
    }.to change(payroll_run.reload.payments, :count).by(-1)

    expect(payroll_run.reload.payments).to_not include(payment_to_delete)

    expect(page).to have_content("You have removed a payment from the payroll run")
    expect(page).to have_content(claim_reference)
  end

  scenario "Service operator can upload a Payment Confirmation Report against a payroll run" do
    payroll_run = create(:payroll_run, claims_counts: {StudentLoans => 2})

    click_on "Payroll"

    click_on "Upload"

    expect(page).to have_content("Upload Payment Confirmation Report")

    csv = <<~CSV
      Payroll Reference,Gross Value,Payment ID,NI,Employers NI,Student Loans,Tax,Net Pay,Claim Policies,Postgraduate Loans
      DFE00001,448.5,#{payroll_run.payments[0].id},33.9,38.98,0,89.6,325,StudentLoans,0.00
      DFE00002,814.64,#{payroll_run.payments[1].id},77.84,89.51,40,162.8,534,StudentLoans,0.00
    CSV

    file = Tempfile.new
    file.write(csv)
    file.rewind

    attach_file("Upload a Payment Confirmation Report CSV file", file.path)
    perform_enqueued_jobs { click_on "Upload file" }

    expect(page).to have_content("Payment Confirmation Report successfully uploaded")

    expect(page.find("table")).to have_content("Uploaded")

    expect(payroll_run.reload.confirmation_report_uploaded_by).to eq(@signed_in_user)
    expect(payroll_run.payments[0].reload.gross_value).to eq("448.5".to_d + "38.98".to_d)
    expect(payroll_run.payments[0].reload.gross_pay).to eq("448.5".to_d)

    expect(ActionMailer::Base.deliveries.count).to eq(2)

    subjects = ActionMailer::Base.deliveries.map { |delivery| delivery.subject }
    addressees = ActionMailer::Base.deliveries.map { |delivery| delivery.to }

    expect(addressees).to match_array([
      [payroll_run.claims[0].email_address],
      [payroll_run.claims[1].email_address]
    ])

    expect(subjects).to match_array([
      "We’re paying your claim to get back your student loan repayments, reference number: #{payroll_run.claims[0].reference}",
      "We’re paying your claim to get back your student loan repayments, reference number: #{payroll_run.claims[1].reference}"
    ])
  end

  scenario "There are no claims or topups" do
    click_on "Payroll"
    month_name = Date.today.strftime("%B")
    click_on "Run #{month_name} payroll"
    click_on "Confirm and submit"

    expect(page).to have_content("Payroll not run, no claims or top ups")
  end
end
