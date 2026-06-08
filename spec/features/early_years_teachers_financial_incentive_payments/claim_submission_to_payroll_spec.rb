require "rails_helper"

RSpec.describe "Full end to end EYTRP", feature_flag: [:eytfi_journey] do
  let(:claimant_email) { "john.doe@example.com" }
  let(:claimant_nino) { "AB123456C" }
  let(:claimant_date_of_birth) { Date.new(1970, 12, 13) }

  before do
    stub_const(
      "Policies::EarlyYearsTeachersFinancialIncentivePayments::APPROVED_MIN_QA_THRESHOLD",
      0
    )

    create(
      :journey_configuration,
      :early_years_teachers_financial_incentive_payments
    )

    create(:eligible_eytfi_provider, name: "Springfield nursery")

    create(
      :student_loans_data,
      nino: claimant_nino,
      date_of_birth: claimant_date_of_birth,
      no_of_plans_currently_repaying: 1,
      plan_type_of_deduction: 1
    )

    OmniAuth.config.mock_auth[:teacher] = OmniAuth::AuthHash.new({
      provider: "teacher",
      extra: {
        raw_info: {
          sub: "urn:fdc:gov.uk:2022:#{SecureRandom.base64(30)}",
          trn: "1234567",
          email: claimant_email,
          verified_name: ["John", "Doe"],
          verified_date_of_birth: claimant_date_of_birth.iso8601
        }
      }
    })

    stub_request(:get, "https://dqt-api.education.gov.uk/v3/persons/1234567")
      .to_return(
        status: 200,
        headers: {
          "Content-Type" => "application/json"
        },
        body: {
          emailAddress: claimant_email,
          dateOfBirth: claimant_date_of_birth.iso8601,
          firstName: "John",
          lastName: "Doe",
          trn: "1234567",
          qts: {
            holdsFrom: "2020-01-01",
            routes: [
              routeToProfessionalStatusType: {
                professionalStatusType: "QualifiedTeacherStatus"
              }
            ]
          }
        }.to_json
      )
  end

  around do |example|
    travel_to DateTime.new(2026, 5, 28, 11, 0, 0) do
      example.run
    end
  end

  scenario "claimant submits a claim, admin approves it and runs payroll" do
    # Claimant journey
    visit landing_page_path(
      Journeys::EarlyYearsTeachersFinancialIncentivePayments.routing_name
    )

    click_link "Start now"

    expect(page).to have_text "Which nursery do you teach in?"
    find_field("claim[nursery_search_query]").set("Springfield nursery")
    click_button "Continue"

    expect(page).to have_text "Which nursery do you teach in?"
    choose "Springfield nursery"
    click_button "Continue"

    expect(page).to have_text "Do you hold one of these teaching qualifications?"
    choose "Yes"
    click_button "Continue"

    expect(page).to have_text "Check if you’re eligible"
    check "I spend at least half"
    check "I’m not currently subject"
    click_button "Confirm and continue"

    expect(page).to have_text "You’re eligible to apply"
    click_button "Continue"

    expect(page).to have_text "Sign in with GOV.UK One Login"
    perform_enqueued_jobs { click_button "Continue" }

    expect(page).to have_text "You may be eligible for a recognition payment"
    choose "Yes"
    click_button "Continue"

    upload_employment_proof

    expect(page).to have_text "How we’ll use your information"
    click_button "Continue"

    expect(page).to have_text "What is your home address?"
    click_button "Enter your address manually"

    fill_in "House number or name", with: "1"
    fill_in "Building and street", with: "Grey Street"
    fill_in "Town or city", with: "Newcastle upon Tyne"
    fill_in "County", with: "Tyne and Wear"
    fill_in "Postcode", with: "NE1 6EE"
    click_button "Continue"

    expect(page).to have_text "Are you recorded as male or female on your employer’s payroll system?"
    choose "I don’t know"
    click_button "Continue"

    expect(page).to have_text "Enter your National Insurance number"
    fill_in "Enter your National Insurance number", with: claimant_nino
    click_button "Continue"

    expect(page).to have_text "Enter your personal bank account details"
    fill_in "Name on your account", with: "John Doe"
    fill_in "Sort code", with: "123456"
    fill_in "Account number", with: "12345678"
    click_button "Continue"

    expect(page).to have_text "Confirm your details and complete your claim"
    check "I confirm that I understand and accept these conditions."

    perform_enqueued_jobs do
      expect { click_button "Confirm and claim" }
        .to change { Claim.count }.by(1)
    end

    expect(page).to have_text "Your reference number"

    claim = Claim.last

    expect(claim.email_address).to eql claimant_email
    expect(claim.student_loan_plan).to eql StudentLoan::PLAN_1
    expect(claim.submitted_using_slc_data).to be true

    # Admin site
    sign_in_as_service_admin

    visit admin_claims_path

    within "#filters" do
      select "Early Years Teachers Recognition Payments", from: "Policy"
      click_on "Apply filters"
    end

    click_on claim.reference

    # Check TRN pulled over from trs
    expect(page).to have_text "1234567"

    expect(page).to have_text "1. Identity confirmation"
    expect(page).to have_text "2. Qualifications"
    expect(page).to have_text "3. Employment"
    expect(page).to have_text "4. Payroll details"
    expect(page).to have_text "5. Payroll gender"

    click_on("Confirm the claimant made the claim")
    expect(page).to have_content("Passed")
    expect(page).to have_content(
      "Identity confirmed by One login on 28/5/2026"
    )
    click_on "Next"

    expect(page).to have_content(
      "Qualification verified as"
    )
    expect(page).to have_content("Passed")
    expect(page).to have_content(
      "This task was performed by an automated check on 28 May 2026"
    )
    click_on "Next"

    expect(page).to have_content("Do you want to accept this evidence?")
    choose "Yes"
    click_on "Save and continue"

    expect(page).to have_content(
      "Has the claimant confirmed their personal bank account details?"
    )
    choose "Yes"
    click_on "Save and continue"

    expect(page).to have_content(
      "How is the claimant’s gender recorded for payroll purposes?"
    )
    choose "Female"
    click_on "Save and continue"

    expect(page).to have_content("Claim decision")
    choose "Approve"
    fill_in "Decision notes", with: "All checks passed"

    perform_enqueued_jobs { click_on "Confirm decision" }

    expect(claim.reload.latest_decision).to be_approved

    expect(claimant_email).to have_received_email(
      ApplicationMailer::EARLY_YEARS_TEACHERS_FINANCIAL_INCENTIVE_PAYMENTS[
        :CLAIM_APPROVED_NOTIFY_TEMPLATE_ID
      ],
      ref_number: claim.reference,
      first_name: "John"
    )

    # Payroll
    click_on "Payroll"

    click_on "Run #{Date.today.strftime("%B")} payroll"

    expect(page).to have_content "Approved claims 1"
    expect(page).to have_content "Total award amount £4,500.00"

    click_on "Confirm and submit"

    expect(page).to have_content "Payroll run created"

    perform_enqueued_jobs

    click_on "Refresh"

    payroll_run = PayrollRun.order(:created_at).last

    expect(payroll_run.claims).to include(claim)
    expect(payroll_run.total_award_amount).to eql(BigDecimal(4500))

    visit new_admin_payroll_run_download_path(payroll_run)

    click_on "Download payroll file"

    click_on "Download May payroll file"

    expect(page.response_headers["Content-Type"]).to eq("text/csv")

    csv = CSV.parse(body, headers: true)

    claim_row = csv.first

    expect(claim_row["TITLE"]).to eq("Prof.")
    expect(claim_row["FORENAME"]).to eq("John")
    expect(claim_row["FORENAME2"]).to eq(nil)
    expect(claim_row["SURNAME"]).to eq("Doe")
    expect(claim_row["SS_NO"]).to eq("AB123456C")
    expect(claim_row["GENDER"]).to eq("F")
    expect(claim_row["MARITAL_STATUS"]).to eq("Other")
    expect(claim_row["START_DATE"]).to eq("01/05/2026")
    expect(claim_row["END_DATE"]).to eq("31/05/2026")
    expect(claim_row["BIRTH_DATE"]).to eq("13/12/1970")
    expect(claim_row["EMAIL"]).to eq("john.doe@example.com")
    expect(claim_row["ADDR_LINE_1"]).to eq(nil)
    expect(claim_row["ADDR_LINE_2"]).to eq("1, Grey Street")
    expect(claim_row["ADDR_LINE_3"]).to eq(nil)
    expect(claim_row["ADDR_LINE_4"]).to eq("Newcastle upon Tyne")
    expect(claim_row["ADDR_LINE_5"]).to eq("Tyne and Wear")
    expect(claim_row["ADDR_LINE_6"]).to eq("NE1 6EE")
    expect(claim_row["ADDRESS_COUNTRY"]).to eq("United Kingdom")
    expect(claim_row["TAX_CODE"]).to eq("BR")
    expect(claim_row["TAX_BASIS"]).to eq("0")
    expect(claim_row["NI_CATEGORY"]).to eq("A")
    expect(claim_row["CON_STU_LOAN_I"]).to eq("T")
    expect(claim_row["PLAN_TYPE"]).to eq("1")
    expect(claim_row["PAYMENT_METHOD"]).to eq("Direct BACS")
    expect(claim_row["PAYMENT_FREQUENCY"]).to eq("Weekly")
    expect(claim_row["BANK_NAME"]).to eq("John Doe")
    expect(claim_row["SORT_CODE"]).to eq("12-34-56")
    expect(claim_row["ACCOUNT_NUMBER"]).to eq("12345678")
    expect(claim_row["ROLL_NUMBER"]).to eq(nil)
    expect(claim_row["SCHEME_AMOUNT"]).to eq("4500.0")
    expect(claim_row["PAYMENT_ID"]).to eq(payroll_run.payments.first.id.to_s)
    expect(claim_row["CLAIM_POLICIES"]).to eq("EarlyYearsTeachersFinancialIncentivePayments")
    expect(claim_row["RIGHT_TO_WORK_CONFIRM_STATUS"]).to eq("2")
  end
end
