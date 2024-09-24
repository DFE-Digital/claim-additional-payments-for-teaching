require "rails_helper"

RSpec.feature "Further education payments" do
  include ActionView::Helpers::NumberHelper

  let(:college) { create(:school, :further_education, :fe_eligible) }
  let(:expected_award_amount) { college.eligible_fe_provider.max_award_amount }

  scenario "happy path claim" do
    when_student_loan_data_exists
    when_further_education_payments_journey_configuration_exists
    and_college_exists

    visit landing_page_path(Journeys::FurtherEducationPayments::ROUTING_NAME)
    expect(page).to have_link("Start now")
    click_link "Start now"

    expect(page).to have_content("Are you a member of staff with teaching responsibilities?")
    choose "Yes"
    click_button "Continue"

    expect(page).to have_content("Which FE provider are you employed by?")
    fill_in "Which FE provider are you employed by?", with: college.name
    click_button "Continue"

    expect(page).to have_content("Select where you are employed")
    choose college.name
    click_button "Continue"

    expect(page).to have_content("What type of contract do you have with #{college.name}?")
    choose("Permanent contract")
    click_button "Continue"

    expect(page).to have_content("On average, how many hours per week are you timetabled to teach at #{college.name} during the current term?")
    choose("12 hours or more per week")
    click_button "Continue"

    expect(page).to have_content("Which academic year did you start teaching in further education (FE) in England?")
    choose("September 2023 to August 2024")
    click_button "Continue"

    expect(page).to have_content("Which subject areas do you teach?")
    check("Building and construction")
    check("Chemistry")
    check("Computing, including digital and ICT")
    check("Early years")
    check("Engineering and manufacturing, including transport engineering and electronics")
    check("Maths")
    check("Physics")
    click_button "Continue"

    expect(page).to have_content("Which building and construction courses do you teach?")
    check "T Level in building services engineering for construction"
    click_button "Continue"

    expect(page).to have_content("Which chemistry courses do you teach?")
    check "GCSE chemistry"
    click_button "Continue"

    expect(page).to have_content("Which computing courses do you teach?")
    check "T Level in digital support services"
    click_button "Continue"

    expect(page).to have_content("Which early years courses do you teach?")
    check "T Level in education and early years (early years educator)"
    click_button "Continue"

    expect(page).to have_content("Which engineering and manufacturing courses do you teach?")
    check "T Level in design and development for engineering and manufacturing"
    click_button "Continue"

    expect(page).to have_content("Which maths courses do you teach?")

    check("claim-maths-courses-approved-level-321-maths-field")
    click_button "Continue"

    expect(page).to have_content("Which physics courses do you teach?")
    check "A or AS level physics"
    click_button "Continue"

    expect(page).to have_content("Do you spend at least half of your timetabled teaching hours teaching these eligible courses?")
    expect(page).to have_content("T Level in building services engineering for construction")
    expect(page).to have_content("GCSE chemistry")
    expect(page).to have_content("T Level in digital support services")
    expect(page).to have_content("T Level in education and early years (early years educator)")
    expect(page).to have_content("T Level in design and development for engineering and manufacturing")
    expect(page).to have_content("Qualifications approved for funding at level 3 and below in the")
    expect(page).to have_content("A or AS level physics")
    choose("Yes")
    click_button "Continue"

    expect(page).to have_content("Are at least half of your timetabled teaching hours spent teaching 16 to 19-year-olds, including those up to age 25 with an Education, Health and Care Plan (EHCP)?")
    choose "Yes"
    click_button "Continue"

    expect(page).to have_content("Do you have a teaching qualification?")
    choose("Yes")
    click_button "Continue"

    expect(page).to have_content("Have any performance measures been started against you?")
    within all(".govuk-fieldset")[0] do
      choose("No")
    end
    expect(page).to have_content("Are you currently subject to disciplinary action?")
    within all(".govuk-fieldset")[1] do
      choose("No")
    end
    click_button "Continue"

    expect(page).to have_content("Check your answers")
    click_button "Continue"

    expect(page).to have_content("You’re eligible for a targeted retention incentive payment")
    expect(page).to have_content(number_to_currency(expected_award_amount, precision: 0))
    expect(page).to have_content("Apply now")
    click_button "Apply now"

    sign_in_with_one_login

    expect(page).to have_content("How we will use the information you provide")
    click_button "Continue"

    expect(page).to have_content("Personal details")
    fill_in "First name", with: "John"
    fill_in "Last name", with: "Doe"
    fill_in "Day", with: "28"
    fill_in "Month", with: "2"
    fill_in "Year", with: "1988"
    fill_in "National Insurance number", with: "PX321499A"
    click_on "Continue"

    expect(page).to have_content("What is your home address?")
    click_link("Enter your address manually")

    expect(page).to have_content("What is your address?")
    fill_in "House number or name", with: "57"
    fill_in "Building and street", with: "Walthamstow Drive"
    fill_in "Town or city", with: "Derby"
    fill_in "County", with: "City of Derby"
    fill_in "Postcode", with: "DE22 4BS"
    click_on "Continue"

    expect(page).to have_content("Email address")
    fill_in "Email address", with: "johndoe@example.com"
    click_on "Continue"

    expect(page).to have_content("Enter the 6-digit passcode")
    mail = ActionMailer::Base.deliveries.last
    otp_in_mail_sent = mail[:personalisation].decoded.scan(/\b[0-9]{6}\b/).first
    fill_in "claim-one-time-password-field", with: otp_in_mail_sent
    click_on "Confirm"

    expect(page).to have_content("Would you like to provide your mobile number?")
    choose "No"
    click_on "Continue"

    expect(page).to have_content("What account do you want the money paid into?")
    choose "Personal bank account"
    click_on "Continue"

    expect(page).to have_content("Enter your personal bank account details")
    fill_in "Name on your account", with: "Jo Bloggs"
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

    expect do
      click_on "Accept and send"
    end.to change { Claim.count }.by(1)
      .and change { Policies::FurtherEducationPayments::Eligibility.count }.by(1)
      .and have_enqueued_mail(ClaimMailer, :submitted).with(Claim.last)

    claim = Claim.last

    expect(claim.first_name).to eql("John")
    expect(claim.surname).to eql("Doe")
    expect(claim.student_loan_plan).to eq "plan_1"

    eligibility = Policies::FurtherEducationPayments::Eligibility.last

    expect(eligibility.teacher_reference_number).to eql("1234567")

    expect(page).to have_content("You applied for a further education targeted retention incentive payment")
    click_link "Set reminder"

    expect(page).to have_content("Personal details")
    fill_in "Full name", with: "John Doe"
    fill_in "Email address", with: "john.doe@example.com"
    click_button "Continue"

    expect(page).to have_content("Enter the 6-digit passcode")
    mail = ActionMailer::Base.deliveries.last
    otp_in_mail_sent = mail[:personalisation].decoded.scan(/\b[0-9]{6}\b/).first
    fill_in "Enter the 6-digit passcode", with: otp_in_mail_sent

    expect do
      click_on "Confirm"
    end.to change { ActionMailer::Base.deliveries.count }.by(1)
      .and change { Reminder.count }.by(1)

    reminder = Reminder.last

    expect(reminder.full_name).to eql("John Doe")
    expect(reminder.email_address).to eql("john.doe@example.com")
    expect(reminder.email_verified).to be_truthy
    expect(reminder.itt_academic_year).to eql(AcademicYear.next.to_s)

    expect(page).to have_content("We have set your reminder")
  end

  def and_college_exists
    college
  end
end
