require "rails_helper"

RSpec.describe "Provider flagging" do
  it "flags any claims from providers in the CSV" do
    create(:journey_configuration, :further_education_payments)

    provider = create(:eligible_fe_provider, :with_school, ukprn: 999999)

    csv = File.open(
      Rails.root.join("spec", "fixtures", "files", "provider_flags.csv")
    )

    sign_in_as_service_admin

    visit admin_journey_configurations_path
    click_on "Change Claim a targeted retention incentive payment for further education teachers"

    attach_file "Upload flagged FE providers CSV", csv.path
    click_button "Upload flagged FE providers"

    expect(page).to have_content("Flagged providers CSV uploaded successfully.")

    claim = submit_fe_claim_for_flagged_claimant(provider)

    visit new_admin_claim_decision_path(claim)

    expect(page).to have_content(
      "You cannot approve this claim until the Provider check task is passed"
    )

    visit admin_claim_tasks_path(claim)

    expect(page).to have_content("Provider check")

    click_on "Check the provider's response"

    expect(page).to have_content(
      "Claims from this provider have been flagged for additional review"
    )

    within_fieldset(
      "Has the provider's response been checked for accuracy?"
    ) { choose "Yes" }

    click_on "Save and continue"

    visit new_admin_claim_decision_path(claim)

    expect(page).not_to have_content(
      "You cannot approve this claim until the Provider check task is passed"
    )
  end

  def submit_fe_claim_for_flagged_claimant(provider)
    school = provider.school

    visit landing_page_path(Journeys::FurtherEducationPayments.routing_name)
    click_link "Start now"

    expect(page).to have_content("Do you have a")
    choose "Yes"
    click_button "Continue"

    sign_in_with_one_login

    expect(page).to have_content(
      "Make a claim for a targeted retention incentive payment for further education"
    )
    click_button "Start eligibility check"

    expect(page).to have_content("Are you a member of staff with the responsibilities of a teacher?")
    choose "Yes"
    click_button "Continue"

    expect(page).to have_content("Which further education provider directly employs you?")
    fill_in "claim[provision_search]", with: school.name
    click_button "Continue"

    expect(page).to have_content("Select where you are employed")
    choose school.name
    click_button "Continue"

    expect(page).to have_content("Which academic year did you start your further education (FE) teaching career in England?")
    choose("September 2024 to August 2025")
    click_button "Continue"

    expect(page).to have_content("Do you have a teaching qualification?")
    choose("Yes")
    click_button "Continue"

    expect(page).to have_content("What type of contract do you have directly with #{school.name}?")
    choose("Permanent")
    click_button "Continue"

    expect(page).to have_content("On average, how many hours per week are you timetabled to teach at #{school.name} during the current term?")
    choose("12 or more hours per week, but fewer than 20")
    click_button "Continue"

    expect(page).to have_content("Do you spend at least half of your timetabled teaching hours teaching students on 16 to 19 study programmes, T Levels or 16 to 19 apprenticeships?")
    choose "Yes"
    click_button "Continue"

    expect(page).to have_content("Which subject areas do you teach?")
    check("Physics")
    click_button "Continue"

    expect(page).to have_content("Which physics courses do you teach?")
    check "A or AS level physics"
    click_button "Continue"

    expect(page).to have_content("Do you spend at least half of your timetabled teaching hours teaching these eligible courses?")
    choose("Yes")
    click_button "Continue"

    expect(page).to have_content("Are you currently subject to any formal performance measures as a result of continuous poor teaching standards")
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
    expect(page).to have_content("Apply now")
    click_button "Apply now"

    idv_with_one_login

    click_button "Continue"

    expect(page).to have_content("Personal details")
    fill_in "National Insurance number", with: "ab123456c" # NINO from claimant_flagging.csv
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

    expect(page).to have_content("Check your answers before sending your application")

    check "I have checked the details I’ve provided and I’m confident they are correct and the bank details match those held by my FE employer for the account my wages are paid into. I understand that submitting incorrect information may cause a delay to any payment."

    # Stub dqt api call in verifiers job
    dqt_teacher_resource = instance_double(Dqt::TeacherResource, find: nil)
    dqt_client = instance_double(Dqt::Client, teacher: dqt_teacher_resource)
    allow(Dqt::Client).to receive(:new).and_return(dqt_client)

    perform_enqueued_jobs do
      click_on "Accept and send"
    end

    expect(page).to have_content("You applied for a further education targeted retention incentive payment")

    Claim.order(:created_at).last
  end
end
