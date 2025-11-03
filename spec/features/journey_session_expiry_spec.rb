require "rails_helper"

RSpec.describe "Journey session expiry" do
  let(:college) { create(:school, :further_education, :fe_eligible) }

  before do
    create(
      :journey_configuration,
      :further_education_payments
    )
  end

  scenario "after session expiry starts new session" do
    when_college_exists

    visit landing_page_path(Journeys::FurtherEducationPayments.routing_name)
    click_link "Start now"

    expect(page).to have_text "Do you have a GOV.UK One Login account?"
    choose "Yes"
    click_button "Continue"

    sign_in_with_one_login

    expect(page).to have_content("Make a claim for a targeted retention incentive payment for further education")
    click_button "Start eligibility check"

    expect(page).to have_content("Are you a member of staff with the responsibilities of a teacher?")
    choose "Yes"
    click_button "Continue"

    expect(page).to have_content("Which further education provider directly employs you?")
    fill_in "claim[provision_search]", with: college.name
    click_button "Continue"

    expect(page).to have_content("Select where you are employed")
    choose college.name
    click_button "Continue"

    expect(page).to have_text("Which academic year did you start teaching in further education in England?")
    choose("September 2023 to August 2024")
    click_button "Continue"

    expect(page).to have_text("Do you have a teaching qualification?")
    last_path = current_path

    travel(2.days)
    ExpireJourneySessionsJob.perform_now

    visit last_path
    expect(page).not_to have_text("Do you have a teaching qualification?")
    expect(page).to have_link "Start now"
  end

  scenario "when on the completion page and session is lost it doesn't error" do
    when_college_exists

    visit landing_page_path(Journeys::FurtherEducationPayments.routing_name)
    click_link "Start now"

    expect(page).to have_text "Do you have a GOV.UK One Login account?"
    choose "No"
    click_button "Continue"

    expect(page).to have_content("Did you apply for a")
    choose "No"
    click_button "Continue"

    expect(page).to have_content("Make a claim for a targeted retention incentive payment for further education")
    click_button "Start eligibility check"

    expect(page).to have_content("Are you a member of staff with the responsibilities of a teacher?")
    choose "Yes"
    click_button "Continue"

    expect(page).to have_content("Which further education provider directly employs you?")
    fill_in "claim[provision_search]", with: college.name
    click_button "Continue"

    expect(page).to have_content("Select where you are employed")
    choose college.name
    click_button "Continue"

    expect(page).to have_text("Which academic year did you start teaching in further education in England?")
    choose("September 2023 to August 2024")
    click_button "Continue"

    expect(page).to have_text("Do you have a teaching qualification?")
    choose "Yes"
    click_button "Continue"

    expect(page).to have_text("What type of contract do you have")
    choose "Permanent"
    click_button "Continue"

    expect(page).to have_text("On average, how many hours per week are you timetabled to teach")
    choose("12 or more hours per week, but fewer than 20")
    click_button "Continue"

    expect(page).to have_text("Do you spend at least half of your timetabled teaching hours teaching students on 16 to 19 study programmes, T Levels or 16 to 19 apprenticeships?")
    choose "Yes"
    click_button "Continue"

    expect(page).to have_text("Which subject areas do you teach?")
    check "Physics"
    click_button "Continue"

    expect(page).to have_text("Which physics courses do you teach?")
    check "A or AS level physics"
    click_button "Continue"

    expect(page).to have_text("Do you spend at least half of your timetabled teaching hours teaching these eligible courses?")
    choose "Yes"
    click_button "Continue"

    expect(page).to have_text("Tell us if you are currently under any performance measures or disciplinary action")
    all("input[type='radio'][value='false']").each(&:click)
    click_button "Continue"

    expect(page).to have_text("Check your answers")
    click_button "Continue"

    click_on "Apply now"

    sign_in_with_one_login
    idv_with_one_login

    expect(page).to have_content("How we will use your information")
    click_button "Continue"

    expect(page).to have_content("Personal details")
    fill_in "National Insurance number", with: "PX321499A"
    click_on "Continue"

    expect(page).to have_content("What is your home address?")
    click_button("Enter your address manually")

    expect(page).to have_content("What is your address?")
    fill_in "House number or name", with: "57"
    fill_in "Building and street", with: "Walthamstow Drive"
    fill_in "Town or city", with: "Derby"
    fill_in "County", with: "City of Derby"
    fill_in "Postcode", with: "DE22 4BS"
    click_on "Continue"

    expect(page).to have_content("Email address")
    fill_in "Email address", with: "john.doe@example.com"
    click_on "Continue"

    expect(page).to have_content("Enter the 6-digit passcode")
    mail = ActionMailer::Base.deliveries.last
    otp_in_mail_sent = mail.personalisation[:one_time_password]
    fill_in "claim-one-time-password-field", with: otp_in_mail_sent
    click_on "Confirm"

    expect(page).to have_content("Would you like to provide your mobile number?")
    choose "No"
    click_on "Continue"

    expect(page).to have_content("Enter the bank account details your salary is paid into")
    fill_in "Name on the account", with: "Jo Bloggs"
    fill_in "Sort code", with: "123456"
    fill_in "Account number", with: "87654321"
    click_on "Continue"

    expect(page).to have_content("How is your gender recorded on your employer’s payroll system?")
    choose "Female"
    click_on "Continue"

    expect(page).to have_content("Teacher reference number (TRN)")
    fill_in "claim-teacher-reference-number-field", with: "1234567"
    click_on "Continue"

    expect(page).to have_content("Check your answers before sending your application")
    expect(page).not_to have_content("Do you have a valid passport?")
    expect(page).not_to have_content("Passport number")

    check "claim-claimant-declaration-1-field"

    click_on "Accept and send"

    expect(page).to have_content("You applied for a further education targeted retention incentive payment")
    expect(page).to have_content("Your reference number ")

    page.driver.browser.clear_cookies
    visit current_path

    expect(page.current_path).to eq "/further-education-payments/landing-page"
  end

  def when_college_exists
    college
  end
end
