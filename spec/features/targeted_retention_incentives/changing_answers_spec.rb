require "rails_helper"

RSpec.describe "Changing answers" do
  before do
    create(
      :journey_configuration,
      :targeted_retention_incentive_payments,
      teacher_id_enabled: true
    )
  end

  it "updates the award amount if the school is changed" do
    school_1 = create(
      :school,
      :targeted_retention_incentive_payments_eligible,
      targeted_retention_incentive_payments_award_amount: 2_000
    )

    school_2 = create(
      :school,
      :targeted_retention_incentive_payments_eligible,
      targeted_retention_incentive_payments_award_amount: 5_000
    )

    visit Journeys::TargetedRetentionIncentivePayments.start_page_url

    click_on "Start now"

    # check-eligibility-intro
    click_through_check_eligibility_intro

    # sign-in-or-continue
    click_on "Continue without signing in"

    # current-school
    fill_in "Which school do you teach at?", with: school_1.name
    click_on "Continue"

    # current-school part 2
    choose school_1.name
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

    # check-your-answers-part-one
    click_on "Continue"

    # eligibility-confirmed
    expect(page).to have_text(
      "Based on what you told us, you can apply for a targeted retention " \
      "incentive payment of: £2,000",
      normalize_ws: true
    )

    click_on "Apply now"

    visit "/targeted-retention-incentive-payments/current-school"

    # current-school
    fill_in "Which school do you teach at?", with: school_2.name
    click_on "Continue"

    # current-school part 2
    choose school_2.name
    click_on "Continue"

    # Jump a head to the personal details page after changing the school
    visit "/targeted-retention-incentive-payments/information-provided"
    click_on "Continue"

    expect(page).to have_text("Personal details")

    session = Journeys::TargetedRetentionIncentivePayments::Session.last

    expect(session.answers.award_amount).to eq(5_000)
  end

  it "shows them the ineligible page if they become ineligible after changing an answer" do
    school = create(
      :school,
      :targeted_retention_incentive_payments_eligible
    )

    ineligible_school = create(:school)

    visit Journeys::TargetedRetentionIncentivePayments.start_page_url

    click_on "Start now"

    # check-eligibility-intro
    click_through_check_eligibility_intro

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

    # check-your-answers-part-one
    school_answer = find(
      "div.govuk-summary-list__row",
      text: "Which school do you teach at?"
    )

    within(school_answer) { click_on "Change" }

    # current-school
    fill_in "Which school do you teach at?", with: ineligible_school.name
    click_on "Continue"

    # current-school part 2
    choose ineligible_school.name
    click_on "Continue"

    expect(page).to have_content("The school you have selected is not eligible")
  end

  it "resets dependent answers" do
    school = create(
      :school,
      :targeted_retention_incentive_payments_eligible
    )

    visit Journeys::TargetedRetentionIncentivePayments.start_page_url

    click_on "Start now"

    # check-eligibility-intro
    click_through_check_eligibility_intro

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

    # check-your-answers-part-one
    qualification_answer = find(
      "div.govuk-summary-list__row",
      text: "Which route into teaching did you take?"
    )

    within(qualification_answer) { click_on "Change" }

    # qualification
    choose "Assessment only"
    click_on "Continue"

    # attempt to jump to check answers
    visit "/targeted-retention-incentive-payments/check-your-answers-part-one"

    # eligible-itt-subject
    expect(page).to have_content("Which subject did you do your assessment in?")
    choose "Chemistry"
    click_on "Continue"

    # attempt to jump to check answers
    visit "/targeted-retention-incentive-payments/check-your-answers-part-one"

    # teaching-subject-now
    expect(page).to have_content(
      "Do you spend at least half of your contracted hours teaching " \
      "eligible subjects?"
    )
    choose "Yes"
    click_on "Continue"

    expect(page).to have_content "Check your answers"
  end

  it "handles reverifying changes to mobile number" do
    school = create(
      :school,
      :targeted_retention_incentive_payments_eligible
    )

    visit Journeys::TargetedRetentionIncentivePayments.start_page_url

    click_on "Start now"

    # check-eligibility-intro
    click_through_check_eligibility_intro

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

    # check-your-answers-part-one
    click_on "Continue"

    click_on "Apply now"

    # information-provided
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

    # email-verification
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

    click_link "Change would you like to provide your mobile number?"

    # provide-mobile-number
    choose "Yes"
    click_on "Continue"

    # mobile-number
    stub_sms_code
    fill_in "Mobile number", with: "07474000123"
    click_on "Continue"

    # mobile-verification
    secret = Journeys::TargetedRetentionIncentivePayments::Session.last.answers.mobile_verification_secret
    code = OneTimePassword::Generator.new(secret:).code

    fill_in "Enter the 6-digit passcode", with: code
    click_on "Confirm"

    expect(page).to have_content "Check your answers before sending your application"
    expect(page).to have_content(/Mobile number\s?07474000123/)

    click_on "Change mobile number"

    # mobile-number
    stub_sms_code
    fill_in "Mobile number", with: "07474000124"
    click_on "Continue"

    # mobile-verification
    secret = Journeys::TargetedRetentionIncentivePayments::Session.last.answers.mobile_verification_secret
    code = OneTimePassword::Generator.new(secret:).code

    fill_in "Enter the 6-digit passcode", with: code
    click_on "Confirm"

    expect(page).to have_content "Check your answers before sending your application"
    expect(page).to have_content(/Mobile number\s?07474000124/)
  end

  def stub_sms_code
    fake_message = instance_double(NotifySmsMessage)
    allow(NotifySmsMessage).to receive(:new).and_return(fake_message)
    expect(fake_message).to receive(:deliver!)
  end
end
