require "rails_helper"

RSpec.describe "Accessing a closed service" do
  before do
    create(
      :journey_configuration,
      :further_education_payments,
      :closed,
      availability_message: "This service is closed for submissions"
    )
  end

  context "without a service access link" do
    it "doesn't allow access to the start of the journey" do
      visit landing_page_path(Journeys::FurtherEducationPayments::ROUTING_NAME)

      expect(page).not_to have_content("Start now")
    end

    it "doesn't allow access to pages in the journey" do
      visit claim_path(
        Journeys::FurtherEducationPayments::ROUTING_NAME,
        "teaching-responsibilities"
      )

      expect(page).to have_content("This service is closed for submissions")
    end
  end

  context "with a service access link" do
    it "allows the claimant to submit a claim" do
      service_access_code = create(
        :service_access_code,
        journey: Journeys::FurtherEducationPayments
      )

      visit landing_page_path(
        Journeys::FurtherEducationPayments::ROUTING_NAME,
        service_access_code: service_access_code.code
      )

      click_on "Start now"

      complete_fe_practitioner_journey

      expect(page).to have_content(
        "You applied for a further education targeted retention incentive payment"
      )

      # Check we don't permit code reused
      visit landing_page_path(
        Journeys::FurtherEducationPayments::ROUTING_NAME,
        service_access_code: service_access_code.code
      )

      expect(page).not_to have_content("Start now")
    end
  end

  context "with a service access link for a different journey" do
    it "doesn't allow access to the journey" do
      service_access_code = create(
        :service_access_code,
        journey: Journeys::GetATeacherRelocationPayment
      )

      visit landing_page_path(
        Journeys::FurtherEducationPayments::ROUTING_NAME,
        service_access_code: service_access_code.code
      )

      expect(page).not_to have_content("Start now")
    end
  end

  def complete_fe_practitioner_journey
    college = create(:school, :further_education, :fe_eligible)
    # teaching-responsibilities
    choose "Yes"
    click_button "Continue"

    # further-education-provision-search
    fill_in "Which FE provider are you employed by?", with: college.name
    click_button "Continue"

    # select-provision
    choose college.name
    click_button "Continue"

    # contract-type
    choose("Permanent contract")
    click_button "Continue"

    # teaching-hours-per-week
    choose("12 hours or more per week")
    click_button "Continue"

    # further-education-teaching-start-year
    choose("September 2023 to August 2024")
    click_button "Continue"

    # subjects-taught
    check("Building and construction")
    click_button "Continue"

    # building-construction-courses
    check "T Level in building services engineering for construction"
    click_button "Continue"

    # hours-teaching-eligible-subjects
    choose("Yes")
    click_button "Continue"

    # half-teaching-hours
    choose "Yes"
    click_button "Continue"

    # teaching-qualification
    choose("Yes")
    click_button "Continue"

    # poor-performance
    within all(".govuk-fieldset")[0] do
      choose("No")
    end
    within all(".govuk-fieldset")[1] do
      choose("No")
    end
    click_button "Continue"

    # check-your-answers-part-one
    click_button "Continue"

    # eligible
    click_button "Apply now"

    sign_in_with_one_login

    click_button "Continue"

    # personal-details
    fill_in "First name", with: "John"
    fill_in "Last name", with: "Doe"
    fill_in "Day", with: "28"
    fill_in "Month", with: "2"
    fill_in "Year", with: "1988"
    fill_in "National Insurance number", with: "PX321499A " # deliberate trailing space
    click_on "Continue"

    click_button("Enter your address manually")

    # address
    fill_in "House number or name", with: "57"
    fill_in "Building and street", with: "Walthamstow Drive"
    fill_in "Town or city", with: "Derby"
    fill_in "County", with: "City of Derby"
    fill_in "Postcode", with: "DE22 4BS"
    click_on "Continue"

    # email-address
    fill_in "Email address", with: "john.doe@example.com"
    click_on "Continue"

    # email-verification
    mail = ActionMailer::Base.deliveries.last
    otp_in_mail_sent = mail[:personalisation].decoded.scan(/\b[0-9]{6}\b/).first
    fill_in "claim-one-time-password-field", with: otp_in_mail_sent
    click_on "Confirm"

    # provide-mobile-number
    choose "No"
    click_on "Continue"

    # personal-bank-account
    fill_in "Name on your account", with: "Jo Bloggs"
    fill_in "Sort code", with: "123456"
    fill_in "Account number", with: "87654321"
    click_on "Continue"

    # gender
    choose "Female"
    click_on "Continue"

    # teacher-reference-number
    fill_in "claim-teacher-reference-number-field", with: "1234567"
    click_on "Continue"

    # check-your-answers
    click_on "Accept and send"
  end
end
