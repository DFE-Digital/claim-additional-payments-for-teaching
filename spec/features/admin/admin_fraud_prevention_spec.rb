require "rails_helper"

RSpec.feature "Admin fraud prevention" do
  let(:fraud_risk_csv) do
    File.open(Rails.root.join("spec", "fixtures", "files", "fraud_risk.csv"))
  end

  context "when updating the list of flagged attributes" do
    it "flags any matching claims" do
      flagged_claim_trn = create(
        :claim,
        :submitted,
        eligibility_attributes: {
          teacher_reference_number: "1234567"
        }
      )

      flagged_claim_nino = create(
        :claim,
        :submitted,
        national_insurance_number: "QQ123456C"
      )

      flagged_claim_trn_and_nino = create(
        :claim,
        :submitted,
        eligibility_attributes: {
          teacher_reference_number: "1234567"
        },
        national_insurance_number: "QQ123456C"
      )

      sign_in_as_service_operator
      visit new_admin_fraud_risk_csv_upload_path
      attach_file "Upload fraud risk CSV file", fraud_risk_csv.path
      click_on "Upload"

      expect(page).to have_content(
        "Fraud prevention list uploaded successfully."
      )

      visit admin_claim_tasks_path(flagged_claim_trn)

      expect(page).to have_content(
        "This claim has been flagged as the " \
        "teacher reference number is included on the fraud prevention list."
      )

      visit admin_claim_tasks_path(flagged_claim_nino)

      expect(page).to have_content(
        "This claim has been flagged as the " \
        "national insurance number is included on the fraud prevention list."
      )

      visit admin_claim_tasks_path(flagged_claim_trn_and_nino)

      expect(page).to have_content(
        "This claim has been flagged as the " \
        "national insurance number and teacher reference number are included " \
        "on the fraud prevention list."
      )

      visit new_admin_claim_decision_path(flagged_claim_trn)

      approval_option = find("#decision_approved_true")

      expect(approval_option).to be_disabled

      expect(page).to have_content(
        "This claim cannot be approved because the teacher reference number " \
        "is included on the fraud prevention list."
      )

      visit new_admin_claim_decision_path(flagged_claim_nino)

      approval_option = find("#decision_approved_true")

      expect(approval_option).to be_disabled

      expect(page).to have_content(
        "This claim cannot be approved because the national insurance number " \
        "is included on the fraud prevention list."
      )

      visit new_admin_claim_decision_path(flagged_claim_trn_and_nino)

      approval_option = find("#decision_approved_true")

      expect(approval_option).to be_disabled

      expect(page).to have_content(
        "This claim cannot be approved because the national insurance number " \
        "and teacher reference number are included on the fraud prevention list."
      )

      visit admin_claim_notes_path(flagged_claim_trn)

      within(".hmcts-timeline:first-of-type") do
        expect(page).to have_content(
          "This claim has been flagged as the " \
          "teacher reference number is included on the fraud prevention list."
        )
      end

      visit admin_claim_notes_path(flagged_claim_nino)

      within(".hmcts-timeline:first-of-type") do
        expect(page).to have_content(
          "This claim has been flagged as the " \
          "national insurance number is included on the fraud prevention list."
        )
      end

      visit admin_claim_notes_path(flagged_claim_trn_and_nino)

      within(".hmcts-timeline:first-of-type") do
        expect(page).to have_content(
          "This claim has been flagged as the " \
          "national insurance number and teacher reference number are included " \
          "on the fraud prevention list."
        )
      end
    end
  end

  it "allows for downloading the csv" do
    sign_in_as_service_operator
    visit new_admin_fraud_risk_csv_upload_path
    attach_file "Upload fraud risk CSV file", fraud_risk_csv.path
    click_on "Upload"

    click_on "Download"
    expect(page.body).to eq(fraud_risk_csv.read.chomp)
  end

  it "creates a note for submitted claims" do
    create(
      :risk_indicator,
      field: "national_insurance_number",
      value: "QQ123456C"
    )

    claim = submit_claim(national_insurance_number: "QQ123456C")

    # Stub dqt api call in verifiers job
    dqt_teacher_resource = instance_double(Dqt::TeacherResource, find: nil)
    dqt_client = instance_double(Dqt::Client, teacher: dqt_teacher_resource)
    allow(Dqt::Client).to receive(:new).and_return(dqt_client)

    perform_enqueued_jobs

    sign_in_as_service_operator

    visit admin_claim_notes_path(claim)

    within(".hmcts-timeline:first-of-type") do
      expect(page).to have_content(
        "This claim has been flagged as the " \
        "national insurance number is included on the fraud prevention list."
      )
    end
  end

  def submit_claim(national_insurance_number: "QQ123456C")
    create(:journey_configuration, :targeted_retention_incentive_payments)

    school = create(:school, :targeted_retention_incentive_payments_eligible)

    visit landing_page_path(Journeys::TargetedRetentionIncentivePayments::ROUTING_NAME)
    # - Landing (start)
    click_on "Start now"

    # - Check eligibility intro
    click_on "Start eligibility check"

    click_on "Continue without signing in"

    # /targeted-retention-incentive-payments/current-school
    fill_in :school_search, with: school.name
    click_on "Continue"

    # /targeted-retention-incentive-payments/current-school
    choose school.name
    click_on "Continue"

    # /targeted-retention-incentive-payments/nqt-in-academic-year-after-itt
    choose "Yes"
    click_on "Continue"

    # /targeted-retention-incentive-payments/supply-teacher
    choose "Yes"
    click_on "Continue"

    # /targeted-retention-incentive-payments/entire-term-contract
    choose "Yes"
    click_on "Continue"

    # /targeted-retention-incentive-payments/employed-directly
    choose "Yes, I'm employed by my school"
    click_on "Continue"

    # /targeted-retention-incentive-payments/poor-performance
    within all(".govuk-fieldset")[0] do
      choose("No")
    end
    within all(".govuk-fieldset")[1] do
      choose("No")
    end
    click_on "Continue"

    # /targeted-retention-incentive-payments/qualification
    choose "Postgraduate initial teacher training (ITT)"
    click_on "Continue"

    # /targeted-retention-incentive-payments/itt-year
    choose "2020 to 2021"
    click_on "Continue"

    # /targeted-retention-incentive-payments/eligible-itt-subject
    choose "Chemistry"
    click_on "Continue"

    # /targeted-retention-incentive-payments/teaching-subject-now
    choose "Yes"
    click_on "Continue"

    # /targeted-retention-incentive-payments/check-your-answers-part-one
    click_on "Continue"

    # /targeted-retention-incentive-payments/eligibility-confirmed
    click_on "Apply now"

    # /targeted-retention-incentive-payments/information-provided
    click_on "Continue"

    # /targeted-retention-incentive-payments/personal-details
    fill_in "First name", with: "Seymour"
    fill_in "Last name", with: "Skinner"

    fill_in "Day", with: "1"
    fill_in "Month", with: "6"
    fill_in "Year", with: "1980"

    fill_in "What is your National Insurance number?", with: national_insurance_number

    click_on "Continue"

    # /targeted-retention-incentive-payments/postcode-search
    click_on "Enter your address manually"

    # /targeted-retention-incentive-payments/address
    fill_in "House number or name", with: "123 Main Street"
    fill_in "Building and street", with: "Downtown"
    fill_in "Town or city", with: "Twin Peaks"
    fill_in "County", with: "Washington"
    fill_in "Postcode", with: "TE57 1NG"

    click_on "Continue"

    # /targeted-retention-incentive-payments/email-address
    fill_in "Email address", with: "test@example.com"
    click_on "Continue"

    # /targeted-retention-incentive-payments/email-verification
    mail = ActionMailer::Base.deliveries.last
    otp_in_mail_sent = mail.personalisation[:one_time_password]
    fill_in "Enter the 6-digit passcode", with: otp_in_mail_sent
    click_on "Confirm"

    # /targeted-retention-incentive-payments/provide-mobile-number
    choose "No"
    click_on "Continue"

    # /targeted-retention-incentive-payments/personal-bank-account
    fill_in "Name on your account", with: "Seymour Skinner"
    fill_in "Sort code", with: "123456"
    fill_in "Account number", with: "87654321"
    click_on "Continue"

    # /targeted-retention-incentive-payments/gender
    choose "Male"
    click_on "Continue"

    # /targeted-retention-incentive-payments/teacher-reference-number
    fill_in "What is your teacher reference number (TRN)?", with: "1234567"
    click_on "Continue"

    # /targeted-retention-incentive-payments/check-your-answers
    click_on "Accept and send"

    Claim.order(:created_at).last
  end
end
