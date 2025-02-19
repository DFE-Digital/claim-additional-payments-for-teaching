require "rails_helper"

RSpec.feature "Payroll" do
  before do
    create(:journey_configuration, :additional_payments, current_academic_year: AcademicYear.new(2022)) # The specs assume eligibility amounts based on claim made in the 2022 academic year
    @signed_in_user = sign_in_as_service_operator
  end

  scenario "Service operator creates a payroll run" do
    click_on "Payroll"

    create(:claim, :approved, policy: Policies::StudentLoans)
    create(:claim, :approved, policy: Policies::StudentLoans)
    create(:claim, :approved, policy: Policies::EarlyCareerPayments)
    create(:claim, :approved, policy: Policies::TargetedRetentionIncentivePayments)

    paid_targeted_retention_incentive_claim = nil
    travel_to 2.months.ago do
      targeted_retention_incentive_eligibility = create(:targeted_retention_incentive_payments_eligibility, :eligible, award_amount: 1500.0)
      paid_targeted_retention_incentive_claim = create(:claim, :approved, policy: Policies::TargetedRetentionIncentivePayments, eligibility: targeted_retention_incentive_eligibility)
      create(:payment, :with_figures, claims: [paid_targeted_retention_incentive_claim])
    end

    user = create(:dfe_signin_user)
    create(:topup, claim: paid_targeted_retention_incentive_claim, award_amount: 500, created_by: user)

    month_name = Date.today.strftime("%B")

    click_on "Run #{month_name} payroll"

    expect(page).to have_content("Approved claims 4")
    expect(page).to have_content("Top up payments 1")
    expect(page).to have_content("Total award amount £9,500.00")

    click_on "Confirm and submit"

    expect(page).to have_content("Payroll run created")
    expect(page).to have_content("This payroll run is in progress")

    perform_enqueued_jobs

    click_on "Refresh"

    payroll_run = PayrollRun.order(:created_at).last

    expect(page).to have_content("Approved claims 4")
    expect(page).to have_content("Top ups 1")
    expect(page).to have_content("Created by #{@signed_in_user.full_name}")
    expect(page).to have_content("Total award amount £9,500.00")
    expect(page).to have_field("payroll_run_download_link", with: new_admin_payroll_run_download_url(payroll_run))

    expect(page).to have_content("Student Loans 2 £2,000.00")
    expect(page).to have_content("Early-Career Payments 1 £5,000.00")
    expect(page).to have_content("School Targeted Retention Incentive 1 £2,000.00")
    expect(page).to have_content("School Targeted Retention Incentive Top Ups 1 £500.00")
  end

  context "when a payroll run already exists for the month" do
    scenario "Service operator cannot create a new payroll run" do
      create(:payroll_run, claims_counts: {Policies::StudentLoans => 2}, created_at: 5.minutes.ago)

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

    perform_enqueued_jobs

    click_on "Refresh"

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
    payroll_run = create(:payroll_run, claims_counts: {Policies::EarlyCareerPayments => 1, Policies::StudentLoans => 1})

    click_on "Payroll"
    click_on "View #{I18n.l(payroll_run.created_at.to_date, format: :month_year)} payroll run"

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
    payroll_run = create(:payroll_run, claims_counts: {Policies::EarlyCareerPayments => 1, Policies::StudentLoans => 1})
    payment_to_delete = payroll_run.payments.first
    claim_reference = payment_to_delete.claims.first.reference

    click_on "Payroll"
    click_on "View #{I18n.l(payroll_run.created_at.to_date, format: :month_year)} payroll run"

    find("a[href='#{remove_admin_payroll_run_payment_path(id: payment_to_delete.id, payroll_run_id: payroll_run.id)}']").click

    expect(page).to have_content("Are you sure you want to remove payment #{payment_to_delete.id} from the payroll run?")

    expect {
      click_on "Remove payment"
    }.to change(payroll_run.reload.payments, :count).by(-1)

    expect(payroll_run.reload.payments).to_not include(payment_to_delete)

    expect(page).to have_content("You have removed a payment from the payroll run")
    expect(page).to have_content(claim_reference)
  end

  scenario "Service operator can upload a Payment Confirmation Report multiple times against a payroll run" do
    payroll_run = create(:payroll_run, claims_counts: {Policies::StudentLoans => 3})
    first_payment = payroll_run.payments.ordered[0]
    second_payment = payroll_run.payments.ordered[1]
    third_payment = payroll_run.payments.ordered[2]
    first_claim = first_payment.claims.first
    second_claim = second_payment.claims.first
    third_claim = third_payment.claims.first

    click_on "Payroll"

    click_on "Upload #{I18n.l(payroll_run.created_at.to_date, format: :month_year)} payment confirmation report"

    expect(page).to have_content("Upload Payment Confirmation Report")

    csv = <<~CSV
      Payroll Reference,Gross Value,Payment ID,NI,Employers NI,Student Loans,Tax,Net Pay,Claim Policies,Postgraduate Loans,Payment Date
      DFE00001,448.5,#{first_payment.id},33.9,38.98,0,89.6,325,StudentLoans,0.00,17/07/2023
      DFE00002,814.64,#{second_payment.id},77.84,89.51,40,162.8,534,StudentLoans,0.00,17/07/2023
    CSV

    file = Tempfile.new
    file.write(csv)
    file.rewind

    attach_file("Upload a Payment Confirmation Report CSV file", file.path)
    perform_enqueued_jobs { click_on "Upload file" }

    expect(page).to have_content("Payment Confirmation Report (2 payments) successfully uploaded")

    expect(page.find("table")).to have_content("(2/3 uploaded)")

    expect(payroll_run.reload.payment_confirmations[0].created_by).to eq(@signed_in_user)
    expect(payroll_run.payment_confirmations[0].payments).to eq([first_payment, second_payment])
    expect(first_payment.reload.gross_value).to eq("448.5".to_d + "38.98".to_d)
    expect(first_payment.reload.gross_pay).to eq("448.5".to_d)

    expect(ActionMailer::Base.deliveries.count).to eq(2)

    subjects = ActionMailer::Base.deliveries.map { |delivery| delivery.subject }
    addressees = ActionMailer::Base.deliveries.map { |delivery| delivery.to }

    expect(addressees).to match_array([
      [first_payment.email_address],
      [second_payment.email_address]
    ])

    expect(subjects).to match_array([
      "We’re paying your claim to get back your student loan repayments, reference number: #{first_claim.reference}",
      "We’re paying your claim to get back your student loan repayments, reference number: #{second_claim.reference}"
    ])

    click_on "Payroll"

    click_on "Upload #{I18n.l(payroll_run.created_at.to_date, format: :month_year)} payment confirmation report"

    csv = <<~CSV
      Payroll Reference,Gross Value,Payment ID,NI,Employers NI,Student Loans,Tax,Net Pay,Claim Policies,Postgraduate Loans,Payment Date
      DFE00003,844.14,#{third_payment.id},7.44,19.11,30,132.9,533,StudentLoans,0.00,17/07/2023
    CSV

    file = Tempfile.new
    file.write(csv)
    file.rewind

    attach_file("Upload a Payment Confirmation Report CSV file", file.path)
    perform_enqueued_jobs { click_on "Upload file" }

    expect(page).to have_content("Payment Confirmation Report (1 payment) successfully uploaded")

    expect(page.find("table")).to have_content("Uploaded")

    expect(payroll_run.reload.payment_confirmations[1].created_by).to eq(@signed_in_user)
    expect(payroll_run.payment_confirmations[1].payments).to eq([third_payment])
    expect(third_payment.reload.gross_value).to eq("844.14".to_d + "19.11".to_d)
    expect(third_payment.reload.gross_pay).to eq("844.14".to_d)

    expect(ActionMailer::Base.deliveries.count).to eq(3)

    subject = ActionMailer::Base.deliveries.last.subject
    address = ActionMailer::Base.deliveries.last.to

    expect(address).to eq([third_payment.email_address])

    expect(subject).to eq(
      "We’re paying your claim to get back your student loan repayments, reference number: #{third_claim.reference}"
    )
  end

  scenario "There are no claims or topups" do
    click_on "Payroll"
    month_name = Date.today.strftime("%B")
    click_on "Run #{month_name} payroll"
    click_on "Confirm and submit"

    expect(page).to have_content("Payroll not run, no claims or top ups")
  end

  scenario "Payments can be browsed using pagination" do
    payroll_run = create(:payroll_run, claims_counts: {Policies::StudentLoans => 7})

    stub_const("Pagy::DEFAULT", Pagy::DEFAULT.merge(limit: 5))

    first_page_payments = payroll_run.payments.ordered[0..Pagy::DEFAULT[:limit] - 1]
    second_page_payments = payroll_run.payments.ordered[Pagy::DEFAULT[:limit]..]

    click_on "Payroll"
    click_on "View #{I18n.l(payroll_run.created_at.to_date, format: :month_year)} payroll run"

    aggregate_failures "first page payments only" do
      first_page_payments.map { |payment| expect(page).to have_content payment.id }
      second_page_payments.map { |payment| expect(page).not_to have_content payment.id }

      expect(page).not_to have_content "Previous"
      expect(page).to have_content "Next"
    end

    click_on "Next"

    aggregate_failures "second page payments only" do
      first_page_payments.map { |payment| expect(page).not_to have_content payment.id }
      second_page_payments.map { |payment| expect(page).to have_content payment.id }

      expect(page).to have_content "Previous"
      expect(page).not_to have_content "Next"
    end

    click_on "Previous"

    aggregate_failures "first page payments only" do
      first_page_payments.map { |payment| expect(page).to have_content payment.id }
      second_page_payments.map { |payment| expect(page).not_to have_content payment.id }

      expect(page).not_to have_content "Previous"
      expect(page).to have_content "Next"
    end
  end

  scenario "failed payroll run job show an error message" do
    create(:claim, :approved, policy: Policies::EarlyCareerPayments)

    click_on "Payroll"

    month_name = Date.today.strftime("%B")

    click_on "Run #{month_name} payroll"

    click_on "Confirm and submit"

    allow(Payment).to receive(:create!).and_raise(StandardError)

    expect { perform_enqueued_jobs }.to raise_error(StandardError)

    click_on "Refresh"

    expect(page).to have_content("This payroll run errored")
  end
end
