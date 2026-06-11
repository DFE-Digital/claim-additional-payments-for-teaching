require "rails_helper"

RSpec.feature "TSLR address", slow: true do
  it_behaves_like(
    "an address journey",
    change_address_link: "Change what is your address?",
    check_answers_heading: "Check your answers before sending your application"
  )

  def complete_journey_upto_postcode_search
    create(:journey_configuration, :student_loans)
    school = create(:school, :student_loans_eligible)

    visit Journeys::TeacherStudentLoanReimbursement.start_page_url
    click_on "Start now"

    expect(page).to have_text("Use DfE Identity to sign in")
    click_on "Continue without signing in"

    find("label", text: /Between the start/).click
    click_on "Continue"

    fill_in "Which school were you employed to teach at", with: school.name
    click_on "Continue"
    choose school.name
    click_on "Continue"

    check "Physics"
    click_on "Continue"

    choose "Yes, at #{school.name}"
    click_on "Continue"

    choose "Yes"
    click_on "Continue"

    choose "No"
    click_on "Continue"

    click_on "Continue"

    click_on "Continue"

    fill_in "First name", with: "Seymour"
    fill_in "Last name", with: "Skinner"
    fill_in "Day", with: "23"
    fill_in "Month", with: "10"
    fill_in "Year", with: "1953"
    fill_in "National Insurance number", with: "AB123456C"
    click_on "Continue"

    click_on "Continue"

    expect(page.current_path).to eq "/student-loans/postcode-search"
  end

  def complete_journey_from_address_to_check_answers
    fill_in "Email address", with: "seymour.skinner@springfield-elementary.edut"
    click_on "Continue"

    mail = ActionMailer::Base.deliveries.last
    otp_in_mail_sent = mail.personalisation[:one_time_password]
    fill_in "claim-one-time-password-field", with: otp_in_mail_sent
    click_on "Confirm"

    choose "No"
    click_on "Continue"

    fill_in "Name on your account", with: "Seymour Skinner"
    fill_in "Sort code", with: "123456"
    fill_in "Account number", with: "87654321"
    click_on "Continue"

    choose "Male"
    click_on "Continue"

    fill_in "claim-teacher-reference-number-field", with: "1234567"
    click_on "Continue"

    expect(page).to have_text "Check your answers before sending your application"
  end
end
