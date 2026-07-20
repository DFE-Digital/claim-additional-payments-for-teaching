require "rails_helper"

RSpec.feature "TRI address", slow: true do
  before do
    create(
      :journey_configuration,
      :targeted_retention_incentive_payments,
      current_academic_year: AcademicYear.new(2022)
    )
  end

  it_behaves_like(
    "an address journey",
    change_address_link: "Change what is your address?",
    check_answers_heading: "Check your answers before sending your application"
  )

  def complete_journey_upto_postcode_search
    create(
      :school,
      :targeted_retention_incentive_payments_eligible,
      name: "Springfield Elementary"
    )

    visit Journeys::TargetedRetentionIncentivePayments.start_page_url

    click_on "Start now"

    click_on "Start eligibility check"

    # sign-in-or-continue
    click_on "Continue without signing in"

    # current-school
    fill_in "Which school do you teach at?", with: "Springfield Elementary"
    click_on "Continue"

    # current-school part 2
    choose "Springfield Elementary"
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
    choose "2021 to 2022"
    click_on "Continue"

    # eligible-itt-subject
    choose "Physics"
    click_on "Continue"

    # teaching-subject-now
    choose "Yes"
    click_on "Continue"

    # check answers part one
    click_on "Continue"

    # eligibility-confirmed
    click_on "Apply now"

    # information-provided
    click_on "Continue"

    # Personal details
    fill_in "First name", with: "Seymour"
    fill_in "Last name", with: "Skinner"

    fill_in "Day", with: "23"
    fill_in "Month", with: "10"
    fill_in "Year", with: "1953"

    fill_in "National Insurance number", with: "AB123456C"
    click_on "Continue"

    expect(page.current_path).to eq "/targeted-retention-incentive-payments/postcode-search"
  end

  def complete_journey_from_address_to_check_answers
    # - Email address
    fill_in "Email address", with: "seymour.skinner@springfield-elementary.edut"
    click_on "Continue"

    # - One time password
    mail = ActionMailer::Base.deliveries.last
    otp_in_mail_sent = mail.personalisation[:one_time_password]

    fill_in "claim-one-time-password-field", with: otp_in_mail_sent
    click_on "Confirm"

    # - Provide mobile number
    choose "No"
    click_on "Continue"

    # - Enter bank account details
    fill_in "Name on your account", with: "Seymour Skinner"
    fill_in "Sort code", with: "123456"
    fill_in "Account number", with: "87654321"
    click_on "Continue"

    # - What gender does your school's payroll system associate with you
    choose "Male"
    click_on "Continue"

    # - What is your teacher reference number
    fill_in "claim-teacher-reference-number-field", with: "1234567"
    click_on "Continue"

    expect(page).to have_text("Check your answers before sending your application")
  end
end
