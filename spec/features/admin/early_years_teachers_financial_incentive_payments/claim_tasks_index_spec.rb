require "rails_helper"

RSpec.describe "Task index page for EYTFI claims" do
  it "shows an overview of the claim" do
    eligible_eytfi_provider = create(
      :eligible_eytfi_provider,
      urn: "EY123456",
      name: "Sunny Days Nursery"
    )

    claim = create(
      :claim,
      :submitted,
      policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
      submitted_at: DateTime.new(2026, 5, 13, 13, 30, 0),
      first_name: "Edna",
      surname: "Krabappel",
      date_of_birth: Date.new(1970, 1, 1),
      national_insurance_number: "ab123456c",
      email_address: "e.krabappel@springfield-elementary.edu",
      eligibility_attributes: {
        teacher_reference_number: "T1234567",
        eligible_eytfi_provider_urn: eligible_eytfi_provider.urn,
        award_amount: 4500
      }
    )

    sign_in_as_service_admin

    visit admin_claim_tasks_path(claim)

    within("#claim-summary") do
      expect(page).to have_summary_item(
        key: "TRN",
        value: "T1234567"
      )

      expect(page).to have_summary_item(
        key: "NI number",
        value: "AB123456C"
      )

      expect(page).to have_summary_item(
        key: "Full name",
        value: "Edna Krabappel"
      )

      expect(page).to have_summary_item(
        key: "Date of birth",
        value: "1 January 1970"
      )

      expect(page).to have_summary_item(
        key: "Email address",
        value: "e.krabappel@springfield-elementary.edu"
      )

      expect(page).to have_summary_item(
        key: "Mobile number",
        value: "N/A"
      )

      expect(page).to have_summary_item(
        key: "Reference",
        value: claim.reference
      )

      expect(page).to have_summary_item(
        key: "Submitted",
        value: "13 May 2026 2:30pm"
      )

      expect(page).to have_summary_item(
        key: "Decision due",
        value: "22 July 2026"
      )

      expect(page).to have_summary_item(
        key: "Status",
        value: "Awaiting decision - not on hold"
      )

      expect(page).to have_summary_item(
        key: "Claim amount",
        value: "£4,500.00"
      )

      expect(page).to have_summary_item(
        key: "Provider name",
        value: "Sunny Days Nursery"
      )

      expect(page).to have_summary_item(
        key: "Provider URN",
        value: "EY123456"
      )
    end
  end

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

  it "shows the student loan plan" do
    claim = create(
      :claim,
      :submitted,
      policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
      national_insurance_number: "ab123456c",
      date_of_birth: Date.new(1970, 1, 1)
    )

    create(
      :student_loans_data,
      nino: "ab123456c",
      date_of_birth: Date.new(1970, 1, 1)
    )

    ClaimVerifierJob.perform_now(claim)

    sign_in_as_service_admin

    visit admin_claim_tasks_path(claim)

    click_on "Check student loan plan"

    expect(page).to have_text("Student loan plan Plan 1")
  end

  it "shows the payroll details" do
    claim = create(
      :claim,
      :submitted,
      :bank_details_not_validated,
      policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
      payroll_gender: "dont_know"
    )

    sign_in_as_service_admin

    visit admin_claim_tasks_path(claim)

    click_on "Check bank account details"

    expect(page).to have_text(
      "The claimant’s personal bank account details have not been automatically validated. Has the claimant confirmed their personal bank account details?"
    )

    choose "Yes"

    click_on "Save and continue"

    visit admin_claim_task_path(claim, "payroll_details")

    expect(page).to have_text("Passed")
    expect(page).to have_text("This task was performed by Aaron Admin")
  end

  it "shows the employment" do
    eligible_eytfi_provider = create(
      :eligible_eytfi_provider,
      urn: "EY123456",
      name: "Sunny Days Nursery",
      address_line_1: "1 Nursery Lane",
      address_line_2: "Childcare Park",
      address_line_3: "Sunny Side",
      town: "Townsville",
      postcode: "TS1 2AB"
    )

    claim = create(
      :claim,
      :submitted,
      policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
      submitted_at: DateTime.new(2026, 5, 1, 9, 30, 0),
      eligibility_attributes: {
        eligible_eytfi_provider_urn: eligible_eytfi_provider.urn
      }
    )

    claim.eligibility.employment_proofs.attach(
      io: File.open(Rails.root.join("spec/fixtures/files/employment_proof.pdf")),
      filename: "employment_proof.pdf",
      content_type: "application/pdf"
    )

    claim.eligibility.employment_proofs.attach(
      io: File.open(Rails.root.join("spec/fixtures/files/employment_proof2.pdf")),
      filename: "employment_proof2.pdf",
      content_type: "application/pdf"
    )

    sign_in_as_service_admin

    visit admin_claim_tasks_path(claim)

    click_on "Check employment information"

    expect(page).to have_text("Employment evidence uploaded by claimant on 1/5/2026")

    expect(page).to have_text("Selected nursery")
    expect(page).to have_text("EY123456")
    expect(page).to have_text("Sunny Days Nursery")
    expect(page).to have_text("1 Nursery Lane")
    expect(page).to have_text("Childcare Park")
    expect(page).to have_text("Sunny Side")
    expect(page).to have_text("Townsville")
    expect(page).to have_text("TS1 2AB")

    expect(page).to have_text("Uploaded evidence")
    expect(page).to have_link("employment_proof.pdf", target: "_blank")
    expect(page).to have_link("employment_proof2.pdf", target: "_blank")

    expect(page).to have_text("Do you want to accept this evidence?")

    click_on "Save and continue"

    expect(page).to have_text("You must select ‘Yes’ or ‘No’")

    choose "Yes"
    click_on "Save and continue"

    visit admin_claim_task_path(claim, "employment")

    expect(page).to have_text("Passed")
    expect(page).to have_text("This task was performed by Aaron Admin")
  end

  it "shows the matching details" do
    claim = create(
      :claim,
      :submitted,
      policy: Policies::EarlyYearsTeachersFinancialIncentivePayments
    )

    duplicate_claim = create(
      :claim,
      :submitted,
      policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
      email_address: claim.email_address
    )

    sign_in_as_service_admin

    visit admin_claim_tasks_path(claim)

    click_on "Review matching details from other claims"

    expect(page).to have_text("Is this claim still valid despite having matching details with other claims?")
    expect(page).to have_text(duplicate_claim.reference)

    choose "Yes"

    click_on "Save and continue"

    visit admin_claim_task_path(claim, "matching_details")

    expect(page).to have_text("Passed")
    expect(page).to have_text("This task was performed by Aaron Admin")
  end
end
