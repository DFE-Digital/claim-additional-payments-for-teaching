require "rails_helper"

RSpec.describe "Targeted retention incentives eligible paths" do
  include OmniauthMockHelper

  before { FeatureFlag.enable!(:tri_only_journey) }

  before do
    create(
      :journey_configuration,
      :targeted_retention_incentive_payments_only,
      teacher_id_enabled: true
    )
  end

  after do
    set_mock_auth(nil)
  end

  it "allows the user to submit a claim without using DfE Identity" do
    school = create(
      :school,
      :targeted_retention_incentive_payments_eligible
    )

    visit Journeys::TargetedRetentionIncentivePayments.start_page_url

    click_on "Start now"

    # sign-in-or-continue
    click_on "Continue without signing in"

    # current-school
    fill_in "Which school do you teach at?", with: school.name
    click_on "Continue"

    # current-school part 2
    choose school.name
    click_on "Continue"

    # nqt-in-academic-year-after-itt
    choose "Yes"
    click_on "Continue"

    # supply-teacher
    choose "No"
    click_on "Continue"

    # poor-performance
    all(".govuk-radios__label").select { it.text == "No" }.each(&:click)
    click_on "Continue"

    # qualification
    choose "Postgraduate initial teacher training (ITT)"
    click_on "Continue"

    # itt-year
    choose "2023 to 2024"
    click_on "Continue"

    # eligible-itt-subject
    choose "Physics"
    click_on "Continue"

    # teaching-subject-now
    choose "Yes"
    click_on "Continue"

    expect(page).to have_content "Check your answers"

    expect(page).to have_summary_item(
      key: "Which school do you teach at?",
      value: school.name
    )

    expect(page).to have_summary_item(
      key: "Are you currently teaching as a qualified teacher?",
      value: "Yes"
    )

    expect(page).to have_summary_item(
      key: "Are you currently employed as a supply teacher?",
      value: "No"
    )

    expect(page).to have_summary_item(
      key: "Are you subject to any formal performance measures as a result " \
           "of continuous poor teaching standards?",
      value: "No"
    )

    expect(page).to have_summary_item(
      key: "Are you currently subject to disciplinary action?",
      value: "No"
    )

    expect(page).to have_summary_item(
      key: "Which route into teaching did you take?",
      value: "Postgraduate initial teacher training (ITT)"
    )

    expect(page).to have_summary_item(
      key: "In which academic year did you start your postgraduate initial " \
           "teacher training (ITT)?",
      value: "2023 to 2024"
    )

    expect(page).to have_summary_item(
      key: "Which subject did you do your postgraduate initial teacher " \
           "training (ITT) in?",
      value: "Physics"
    )

    expect(page).to have_summary_item(
      key: "Do you spend at least half of your contracted hours teaching " \
           "eligible subjects?",
      value: "Yes"
    )

    click_on "Continue"

    expect(page).to have_content(
      "You’re eligible for a targeted retention incentive payment"
    )

    expect(page).to have_text(
      "Based on what you told us, you can apply for a targeted retention " \
      "incentive payment of: £2,000",
      normalize_ws: true
    )

    click_on "Apply now"

    # information-provided
    expect(page).to have_text(
      "How we will use the information you provide"
    )
    click_on "Continue"

    # Personal details
    fill_in "First name", with: "Seymour"
    fill_in "Last name", with: "Skinner"

    fill_in "Day", with: "23"
    fill_in "Month", with: "10"
    fill_in "Year", with: "1953"

    fill_in "National Insurance number", with: "QQ123456C"
    click_on "Continue"

    click_on "Enter your address manually"

    fill_in "House number or name", with: "Test house"
    fill_in "Building and street", with: "Test street"
    fill_in "Town or city", with: "Test town"
    fill_in "County", with: "Testshire"
    fill_in "Postcode", with: "TE57 1NG"
    click_on "Continue"

    fill_in "Email address", with: "seymour.skinner@springfield-elementary.edu"
    click_on "Continue"

    mail = ActionMailer::Base.deliveries.last
    otp_in_mail_sent = mail.personalisation[:one_time_password]

    fill_in "Enter the 6-digit passcode", with: otp_in_mail_sent
    click_on "Confirm"

    # provide-mobile-number
    choose "No"
    click_on "Continue"

    fill_in "Name on your account", with: "Seymour Skinner"
    fill_in "Sort code", with: "000000"
    fill_in "Account number", with: "00000000"
    click_on "Continue"

    # gender
    choose "Male"
    click_on "Continue"

    # trn
    fill_in "What is your teacher reference number (TRN)?", with: "1234567"
    click_on "Continue"

    # check-your-answers
    expect(page).to have_content(
      "Check your answers before sending your application"
    )

    expect(page).to have_summary_item(
      key: "What is your full name?",
      value: "Seymour Skinner"
    )

    expect(page).to have_summary_item(
      key: "What is your address?",
      value: "Test house, Test street, Test town, Testshire, TE57 1NG"
    )

    expect(page).to have_summary_item(
      key: "What is your date of birth?",
      value: "23 October 1953"
    )

    expect(page).to have_summary_item(
      key: "How is your gender recorded on your school’s payroll system?",
      value: "Male"
    )

    expect(page).to have_summary_item(
      key: "What is your teacher reference number (TRN)?",
      value: "1234567"
    )

    expect(page).to have_summary_item(
      key: "What is your National Insurance number?",
      value: "QQ123456C"
    )

    expect(page).to have_summary_item(
      key: "Email address",
      value: "seymour.skinner@springfield-elementary.edu"
    )

    expect(page).to have_summary_item(
      key: "Would you like to provide your mobile number?",
      value: "No"
    )

    expect(page).to have_summary_item(
      key: "Name on bank account",
      value: "Seymour Skinner"
    )

    expect(page).to have_summary_item(
      key: "Bank sort code",
      value: "000000"
    )

    expect(page).to have_summary_item(
      key: "Bank account number",
      value: "00000000"
    )

    click_on "Accept and send"

    expect(page).to have_content(
      "You applied for a targeted retention incentive payment"
    )
  end

  it "allows a supply teacher to submit a claim" do
    school = create(
      :school,
      :targeted_retention_incentive_payments_eligible
    )

    visit Journeys::TargetedRetentionIncentivePayments.start_page_url

    click_on "Start now"

    # sign-in-or-continue
    click_on "Continue without signing in"

    # current-school
    fill_in "Which school do you teach at?", with: school.name
    click_on "Continue"

    # current-school part 2
    choose school.name
    click_on "Continue"

    # nqt-in-academic-year-after-itt
    choose "Yes"
    click_on "Continue"

    # supply-teacher
    choose "Yes"
    click_on "Continue"

    # entire-term-contract
    choose "Yes"
    click_on "Continue"

    # employed-directly
    choose "Yes"
    click_on "Continue"

    # poor-performance
    all(".govuk-radios__label").select { it.text == "No" }.each(&:click)
    click_on "Continue"

    # qualification
    choose "Postgraduate initial teacher training (ITT)"
    click_on "Continue"

    # itt-year
    choose "2023 to 2024"
    click_on "Continue"

    # eligible-itt-subject
    choose "Physics"
    click_on "Continue"

    # teaching-subject-now
    choose "Yes"
    click_on "Continue"

    expect(page).to have_content "Check your answers"

    expect(page).to have_summary_item(
      key: "Are you currently employed as a supply teacher?",
      value: "Yes"
    )

    expect(page).to have_summary_item(
      key: "Do you have a contract to teach at the same school for an entire " \
           "term or longer?",
      value: "Yes"
    )

    expect(page).to have_summary_item(
      key: "Are you employed directly by your school?",
      value: "Yes, I'm employed by my school"
    )

    click_on "Continue"

    expect(page).to have_content(
      "You’re eligible for a targeted retention incentive payment"
    )
  end

  it "asks an additional question when selecting non of the above for itt subject" do
    school = create(
      :school,
      :targeted_retention_incentive_payments_eligible
    )

    visit Journeys::TargetedRetentionIncentivePayments.start_page_url

    click_on "Start now"

    # sign-in-or-continue
    click_on "Continue without signing in"

    # current-school
    fill_in "Which school do you teach at?", with: school.name
    click_on "Continue"

    # current-school part 2
    choose school.name
    click_on "Continue"

    # nqt-in-academic-year-after-itt
    choose "Yes"
    click_on "Continue"

    # supply-teacher
    choose "No"
    click_on "Continue"

    # poor-performance
    all(".govuk-radios__label").select { it.text == "No" }.each(&:click)
    click_on "Continue"

    # qualification
    choose "Postgraduate initial teacher training (ITT)"
    click_on "Continue"

    # itt-year
    choose "2023 to 2024"
    click_on "Continue"

    # eligible-itt-subject
    choose "None of the above"
    click_on "Continue"

    # eligible-degree-subject
    expect(page).to have_content("Do you have a degree in an eligible subject?")
    choose "Yes"
    click_on "Continue"

    # teaching-subject-now
    choose "Yes"
    click_on "Continue"

    expect(page).to have_summary_item(
      key: "Which subject did you do your postgraduate initial teacher " \
           "training (ITT) in?",
      value: "None of the above"
    )

    expect(page).to have_summary_item(
      key: "Do you have a degree in an eligible subject?",
      value: "Yes"
    )

    click_on "Continue"

    expect(page).to have_content(
      "You’re eligible for a targeted retention incentive payment"
    )
  end

  it "handles trainee teachers and shows future eligibility information" do
    school = create(
      :school,
      :targeted_retention_incentive_payments_eligible
    )

    visit Journeys::TargetedRetentionIncentivePayments.start_page_url

    click_on "Start now"

    # sign-in-or-continue
    click_on "Continue without signing in"

    # current-school
    fill_in "Which school do you teach at?", with: school.name
    click_on "Continue"

    # current-school part 2
    choose school.name
    click_on "Continue"

    # nqt-in-academic-year-after-itt - select No (trainee teacher)
    choose "No, I’m a trainee teacher"
    click_on "Continue"

    # eligible-itt-subject
    choose "Physics"
    click_on "Continue"

    # future-eligibility
    expect(page).to have_content("You are not eligible this year")
    expect(page).to have_content(
      "You'll be eligible for a targeted retention incentive payment when " \
      "you become a qualified teacher"
    )
  end

  it "handles trainee teachers with non-eligible ITT subject" do
    school = create(
      :school,
      :targeted_retention_incentive_payments_eligible
    )

    visit Journeys::TargetedRetentionIncentivePayments.start_page_url

    click_on "Start now"

    # sign-in-or-continue
    click_on "Continue without signing in"

    # current-school
    fill_in "Which school do you teach at?", with: school.name
    click_on "Continue"

    # current-school part 2
    choose school.name
    click_on "Continue"

    # nqt-in-academic-year-after-itt - select No (trainee teacher)
    choose "No, I’m a trainee teacher"
    click_on "Continue"

    # eligible-itt-subject
    choose "None of the above"
    click_on "Continue"

    # eligible-degree-subject
    expect(page).to have_content("Do you have a degree in an eligible subject?")
    expect(page).to have_content(
      "This can be an undergraduate or postgraduate degree in chemistry, " \
      "languages, mathematics or physics."
    )

    choose "Yes"
    click_on "Continue"

    # Expect to see future eligibility page
    expect(page).to have_content("You are not eligible this year")
    expect(page).to have_content(
      "You'll be eligible for a targeted retention incentive payment when " \
      "you become a qualified teacher"
    )
  end

  it "uses information from teacher id and TPS to speed up the journey" do
    la = create(:local_authority)

    # Presence of a matching TPS record triggers the slug sequence to show
    # the "correct-school"
    tps_record = create(
      :teachers_pensions_service,
      school_urn: 123456,
      teacher_reference_number: 1234567,
      end_date: 1.day.from_now,
      la_urn: la.code
    )

    school = create(
      :school,
      :targeted_retention_incentive_payments_eligible,
      name: "Springfield Elementary School",
      establishment_number: tps_record.school_urn,
      local_authority: la
    )

    set_mock_auth(
      "1234567",
      {
        date_of_birth: "1953-10-23",
        nino: "QQ123456C",
        given_name: "Seymour",
        family_name: "Skinner",
        email: "seymoure.skinner@springfield-elementary.edu",
        email_verified: true
      },
      phone_number: "07700900000"
    )

    stub_qualified_teaching_statuses_show(
      trn: "1234567",
      params: {birthdate: "1953-10-23", nino: "QQ123456C"},
      body: {
        qualified_teacher_status: {
          qts_date: "2023-07-01"
        },
        initial_teacher_training: {
          subject1: "physics",
          subject1_code: "F300"
        }
      }
    )

    visit Journeys::TargetedRetentionIncentivePayments.start_page_url

    click_on "Start now"

    # sign-in-or-continue
    click_on "Continue with DfE Identity"

    # Teacher details page
    expect(page).to have_content("You must check that all details are correct")

    expect(page).to have_summary_item(
      key: "Name",
      value: "Seymour Skinner"
    )

    expect(page).to have_summary_item(
      key: "Date of birth",
      value: "23 October 1953"
    )

    expect(page).to have_summary_item(
      key: "Teacher reference number (TRN)",
      value: "1234567"
    )

    expect(page).to have_summary_item(
      key: "National Insurance number",
      value: "QQ123456C"
    )

    choose "Yes"
    click_on "Continue"

    # correct-school
    choose "Springfield Elementary School"
    click_on "Continue"

    # nqt-in-academic-year-after-itt
    choose "Yes"
    click_on "Continue"

    # supply-teacher
    choose "No"
    click_on "Continue"

    # poor-performance
    all(".govuk-radios__label").select { |it| it.text == "No" }.each(&:click)
    click_on "Continue"

    # Qualification details confirmation page (instead of qualification questions)
    expect(page).to have_content("Check and confirm your qualification details")

    expect(page).to have_summary_item(
      key: "Teacher route taken",
      value: "Undergraduate initial teacher training (ITT)"
    )

    expect(page).to have_summary_item(
      key: "Academic year you completed your undergraduate initial teacher " \
           "training (ITT)",
      value: "2022/2023"
    )

    # Not showing degree subjects as eligible itt subject is not
    # "none_of_the_above"

    expect(page).to have_summary_item(
      key: "Subject you did your undergraduate initial teacher training (ITT) in",
      value: "Physics"
    )

    # confirm qualification details
    choose "Yes"
    click_on "Continue"

    # Skip qualification, itt-year, and eligible-itt-subject questions

    # teaching-subject-now
    expect(page).to have_content(
      "Do you spend at least half of your contracted hours teaching " \
      "eligible subjects?"
    )
    choose "Yes"
    click_on "Continue"

    # check-your-answers-part-one
    expect(page).to have_content("Check your answers")

    click_on "Continue"

    # eligibility-confirmed
    expect(page).to have_content(
      "You’re eligible for a targeted retention incentive payment"
    )
    click_on "Apply now"

    # information-provided
    expect(page).to have_content("How we will use the information you provide")
    click_on "Continue"

    # Personal details page should be skipped since TID provided all details

    # Postcode search
    expect(page).to have_content("What is your home address?")
    click_on "Enter your address manually"

    # Address
    fill_in "House number or name", with: "42"
    fill_in "Building and street", with: "Computation Avenue"
    fill_in "Town or city", with: "Cambridge"
    fill_in "County", with: "Cambridgeshire"
    fill_in "Postcode", with: "CB2 1TN"
    click_on "Continue"

    # select-email
    expect(page).to have_content(
      "Which email address should we use to contact you?"
    )
    choose "seymoure.skinner@springfield-elementary.edu"
    click_on "Continue"

    # select-mobile
    expect(page).to have_content(
      "Which mobile number should we use to contact you?"
    )
    choose "07700900000"
    click_on "Continue"

    # personal-bank-account
    fill_in "Name on your account", with: "Seymour Skinner"
    fill_in "Sort code", with: "000000"
    fill_in "Account number", with: "12345678"
    click_on "Continue"

    # gender
    choose "Male"
    click_on "Continue"

    # teacher-reference-number should be skipped since it's from TID

    # check-your-answers
    expect(page).to have_content(
      "Check your answers before sending your application"
    )

    click_on "Accept and send"

    # Confirmation page
    expect(page).to have_content(
      "You applied for a targeted retention incentive payment"
    )

    # Verify claim details
    # We can't check the content on check your answers as information from TID
    # isn't shown
    claim = Claim.by_policy(
      Policies::TargetedRetentionIncentivePayments
    ).order(created_at: :desc).first

    expect(claim.first_name).to eq("Seymour")
    expect(claim.surname).to eq("Skinner")
    expect(claim.date_of_birth).to eq(Date.new(1953, 10, 23))
    expect(claim.national_insurance_number).to eq("QQ123456C")
    expect(claim.email_address).to eq("seymoure.skinner@springfield-elementary.edu")
    expect(claim.mobile_number).to eq("07700900000")
    expect(claim.logged_in_with_tid).to be true

    eligibility = claim.eligibility

    expect(eligibility.teacher_reference_number).to eq("1234567")
    expect(eligibility.current_school).to eq(school)
    expect(eligibility.eligible_itt_subject).to eq("physics")
    expect(eligibility.qualification).to eq("undergraduate_itt")
    expect(eligibility.itt_academic_year).to eq(AcademicYear.new(2022))
  end

  it "allows restarting a claim if claimant says dfe sign in details don't match" do
    create(
      :school,
      :targeted_retention_incentive_payments_eligible,
      name: "Springfield Elementary School"
    )

    set_mock_auth(
      "1234567",
      {
        date_of_birth: "1953-10-23",
        nino: "QQ123456C",
        given_name: "Seymour",
        family_name: "Skinner",
        email: "seymoure.skinner@springfield-elementary.edu",
        email_verified: true
      },
      phone_number: "07700900000"
    )

    visit Journeys::TargetedRetentionIncentivePayments.start_page_url

    click_on "Start now"

    # sign-in-or-continue
    click_on "Continue with DfE Identity"

    # details-check
    choose "No"
    click_on "Continue"

    expect(page).to have_content(
      "As you have told us that the information we’ve received using your DfE " \
      "Identity account is not correct, you cannot use your DfE Identity " \
      "account with this service."
    )

    click_on "Continue"

    expect(page).to have_content("Which school do you teach at?")
  end

  it "resets the claim if the trn is missing from teacher id" do
    create(
      :school,
      :targeted_retention_incentive_payments_eligible,
      name: "Springfield Elementary School"
    )

    set_mock_auth(
      "1234567",
      {
        returned_trn: nil,
        date_of_birth: "1953-10-23",
        nino: "QQ123456C",
        given_name: "Seymour",
        family_name: "Skinner",
        email: "seymoure.skinner@springfield-elementary.edu",
        email_verified: true
      },
      phone_number: "07700900000"
    )

    visit Journeys::TargetedRetentionIncentivePayments.start_page_url

    click_on "Start now"

    # sign-in-or-continue
    click_on "Continue with DfE Identity"

    # details-check
    choose "Yes"
    click_on "Continue"

    expect(page).to have_content(
      "You don’t currently have a teacher reference number (TRN) " \
      "assigned to your DfE Identity account."
    )

    expect(page).to have_content(
      "You can continue to complete an application to check your eligibility " \
      "and apply for a payment."
    )

    click_on "Continue"

    expect(page).to have_content("Which school do you teach at?")
  end
end
