require "rails_helper"

RSpec.feature "Further education payments address", slow: true do
  it_behaves_like(
    "an address journey",
    change_address_link: "Change address",
    check_answers_heading: "Check your answers before sending your application"
  )

  def complete_journey_upto_postcode_search
    when_student_loan_data_exists
    when_further_education_payments_journey_configuration_exists

    college = create(:school, :further_education, :fe_eligible)

    visit landing_page_path(Journeys::FurtherEducationPayments.routing_name)
    click_link "Start now"

    choose "No"
    click_button "Continue"

    choose "No"
    click_button "Continue"

    click_button "Start eligibility check"

    choose "Yes"
    click_button "Continue"

    fill_in "claim[provision_search]", with: college.name
    click_button "Continue"

    choose college.name
    click_button "Continue"

    choose "September 2023 to August 2024"
    click_button "Continue"

    choose "Yes"
    click_button "Continue"

    choose "Permanent"
    click_button "Continue"

    choose "12 or more hours per week, but fewer than 20"
    click_button "Continue"

    choose "Yes"
    click_button "Continue"

    check "Maths"
    click_button "Continue"

    check "claim-maths-courses-approved-level-321-maths-field"
    click_button "Continue"

    choose "Yes"
    click_button "Continue"

    within all(".govuk-fieldset")[0] do
      choose "No"
    end
    within all(".govuk-fieldset")[1] do
      choose "No"
    end
    click_button "Continue"

    click_button "Continue"

    click_button "Apply now"

    sign_in_with_one_login
    idv_with_one_login

    click_button "Continue"

    fill_in "National Insurance number", with: "PX321499A"
    click_on "Continue"

    expect(page).to have_content "What is your home address?"
  end

  def complete_journey_from_address_to_check_answers
    fill_in "Email address", with: "john.doe@example.com"
    click_on "Continue"

    mail = ActionMailer::Base.deliveries.last
    otp_in_mail_sent = mail.personalisation[:one_time_password]
    fill_in "claim-one-time-password-field", with: otp_in_mail_sent
    click_on "Confirm"

    choose "No"
    click_on "Continue"

    fill_in "Name on the account", with: "Jo Bloggs"
    fill_in "Sort code", with: "123456"
    fill_in "Account number", with: "87654321"
    click_on "Continue"

    choose "Female"
    click_on "Continue"

    expect(page).to have_content "Check your answers before sending your application"
  end
end
