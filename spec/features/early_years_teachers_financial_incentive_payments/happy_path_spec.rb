require "rails_helper"

RSpec.feature "EYTFI journey", feature_flag: [:eytfi_journey] do
  let(:mock_teacher) do
    instance_double(
      "Dqt::Teacher",
      has_eligible_eytfi_qualification?: true
    )
  end

  let(:mock_teacher_resource) do
    instance_double(
      "Dqt::TeacherResource",
      find: mock_teacher
    )
  end

  let(:mock_client) do
    instance_double(
      "Dqt::Client",
      teacher: mock_teacher_resource
    )
  end

  before do
    create(
      :journey_configuration,
      :early_years_teachers_financial_incentive_payments
    )

    OmniAuth.config.mock_auth[:teacher] = OmniAuth::AuthHash.new({
      provider: "teacher",
      extra: {
        raw_info: {
          sub: "urn:fdc:gov.uk:2022:#{SecureRandom.base64(30)}",
          trn: "1234567",
          email: "john.doe@example.com",
          verified_name: ["John", "Doe"],
          verified_date_of_birth: "1970-12-13"
        }
      }
    })

    allow(Dqt::Client).to receive(:new).and_return(mock_client)
  end

  scenario "guidance apply button redirects to the landing page" do
    create(
      :eligible_eytfi_provider,
      name: "Springfield nursery"
    )

    visit eytfi_guidance_path(
      journey: Journeys::EarlyYearsTeachersFinancialIncentivePayments.routing_name
    )

    click_link "Apply to claim a payment"

    expect(page).to have_current_path(
      landing_page_path(
        journey: Journeys::EarlyYearsTeachersFinancialIncentivePayments.routing_name
      )
    )
    expect(page).to have_text "Claim an early years teacher recognition payment"
  end

  scenario "happy path" do
    create(
      :eligible_eytfi_provider,
      name: "Springfield nursery"
    )

    visit landing_page_path(
      Journeys::EarlyYearsTeachersFinancialIncentivePayments.routing_name
    )

    click_link "Start now"

    expect(page).to have_text "Which nursery do you teach in?"
    find_field("claim[nursery_search_query]").set("Springfield nursery")
    click_button "Continue"

    expect(page).to have_text "Which nursery do you teach in?"
    choose "Springfield nursery"
    click_button "Continue"

    expect(page).to have_text "Do you hold one of these teaching qualifications?"
    choose "Yes"
    click_button "Continue"

    expect(page).to have_text "Check that you are eligible"
    check "I spend at least 50%"
    check "I’m not currently subject"
    click_button "Confirm and continue"

    expect(page).to have_text "You are eligible to apply"
    click_button "Continue"

    expect(page).to have_text "Sign in with GOV.UK One Login"
    perform_enqueued_jobs do
      click_button "Continue"
    end

    journey_session = Journeys::EarlyYearsTeachersFinancialIncentivePayments::Session.last

    expect(journey_session.answers.teacher_auth_teacher_reference_number).to eql("1234567")
    expect(journey_session.answers.teacher_auth_email).to eql("john.doe@example.com")
    expect(journey_session.answers.teacher_auth_verified_name).to eql("John Doe")
    expect(journey_session.answers.teacher_auth_verified_date_of_birth).to eql(Date.new(1970, 12, 13))
    expect(journey_session.answers.teacher_auth_one_login_uid).to be_present
    expect(journey_session.answers.teacher_auth_completed_at).to be_within(1.minute).of(Time.zone.now)

    expect(journey_session.answers.trs_data).to be_present
    expect(journey_session.answers.trs_data_fetched_at).to be_within(1.minute).of(Time.zone.now)
    expect(journey_session.answers.has_eligible_qualification).to be_truthy

    expect(page).to have_text "You may be eligible for a recognition payment"
    choose "Yes"
    click_button "Continue"

    upload_employment_proof

    expect(page).to have_text "How we’ll use your information"
    click_button "Continue"

    expect(page).to have_text "What is your home address?"
    click_button "Enter your address manually"

    fill_in "House number or name", with: "1"
    fill_in "Building and street", with: "Grey Street"
    fill_in "Town or city", with: "Newcastle upon Tyne"
    fill_in "County", with: "Tyne and Wear"
    fill_in "Postcode", with: "NE1 6EE"
    click_button "Continue"

    expect(page).to have_text "How is your gender recorded"
    choose "I don’t know"
    click_button "Continue"

    expect(page).to have_text "Enter your National Insurance number"
    fill_in "Enter your National Insurance number", with: "AB123456C"
    click_button "Continue"

    expect(page).to have_text "Enter your personal bank account details"
    fill_in "Name on your account", with: "John Doe"
    fill_in "Sort code", with: "123456"
    fill_in "Account number", with: "12345678"
    click_button "Continue"

    expect(page).to have_text "Confirm your details and complete your claim"
    check "I confirm that I understand and accept these conditions."

    perform_enqueued_jobs do
      expect {
        click_button "Confirm and claim"
      }.to change { Claim.count }.by(1)
        .and change { Policies::EarlyYearsTeachersFinancialIncentivePayments::Eligibility.count }.by(1)
        .and change { ActionMailer::Base.deliveries.count }.by(1)
    end

    claim = Claim.last

    expect(claim.reference).to be_present

    expect(claim.address_line_1).to eql "1"
    expect(claim.address_line_2).to eql "Grey Street"
    expect(claim.address_line_3).to eql "Newcastle upon Tyne"
    expect(claim.address_line_4).to eql "Tyne and Wear"
    expect(claim.postcode).to eql "NE1 6EE"

    expect(claim.banking_name).to eql "John Doe"
    expect(claim.bank_account_number).to eql "12345678"
    expect(claim.bank_sort_code).to eql "123456"

    expect(claim.claimant_declaration).to be_truthy
    expect(claim.decision_deadline).to be_present
    expect(claim.payroll_gender).to eql "dont_know"

    expect(claim.onelogin_uid).to be_present
    expect(claim.date_of_birth).to be_present

    eligibility = claim.eligibility

    expect(eligibility.teacher_auth_completed_at).to be_present
    expect(eligibility.teacher_auth_email).to eql("john.doe@example.com")
    expect(eligibility.teacher_auth_one_login_uid).to be_present
    expect(eligibility.teacher_auth_teacher_reference_number).to eql "1234567"
    expect(eligibility.teacher_auth_verified_date_of_birth).to eql(Date.new(1970, 12, 13))
    expect(eligibility.teacher_auth_verified_name).to eql "John Doe"

    expect(eligibility.award_amount).to eql 4500
    expect(eligibility.confirmed_employment_proof_blob_ids).to be_present
    expect(eligibility.has_eligible_qualification).to be_truthy
    expect(eligibility.nursery_id).to be_present
    expect(eligibility.eligible_eytfi_provider_urn).to be_present

    expect(eligibility.teaching_qualification_confirmation).to be_truthy
    expect(eligibility.trs_data).to be_present
    expect(eligibility.trs_data_fetched_at).to be_present

    mail = ActionMailer::Base.deliveries.last

    expect(mail.template_id).to eql(ApplicationMailer::EARLY_YEARS_TEACHERS_FINANCIAL_INCENTIVE_PAYMENTS[:CLAIM_RECEIVED_NOTIFY_TEMPLATE_ID])
    expect(mail.personalisation[:first_name]).to eql("John")
    expect(mail.personalisation[:ref_number]).to eql(claim.reference)

    expect(page).to have_text "Your reference number"
    click_link "What did you think of this service?"

    expect(page).to have_text "Give feedback on Claim an early years teacher recognition payment"
    choose "Very satisfied"
    choose "Specific page"
    choose "Uploading proof of employment"
    fill_in "How could we improve this service? (optional)", with: "some comment"
    choose "Yes"
    fill_in "What is your email address?", with: "claimant@example.com"
    fill_in "Occupation", with: "Teacher"
    expect {
      click_button "Submit feedback"
    }.to change(Feedback, :count).by(1)

    expect(page).to have_text "Feedback submitted"

    feedback = Feedback.last

    expect(feedback.rating).to eql "very_satisfied"
    expect(feedback.area).to eql "specific_page"
    expect(feedback.specific_page).to eql "uploading"
    expect(feedback.comment).to eql "some comment"
    expect(feedback.research_participation).to be_truthy
    expect(feedback.email_address).to eql "claimant@example.com"
    expect(feedback.occupation).to eql "Teacher"

    expect(feedback.origin).to eql "http://www.example.com/early-years-teachers-recognition-payments/confirmation"
    expect(feedback.claim_id).to eql(claim.id)
  end

  scenario "using nursery auto complete - js", js: true do
    create(
      :eligible_eytfi_provider,
      name: "Springfield nursery"
    )

    visit landing_page_path(
      Journeys::EarlyYearsTeachersFinancialIncentivePayments.routing_name
    )

    click_link "Start now"

    expect(page).to have_text "Which nursery do you teach in?"

    find_field("claim[nursery_search_query]").send_keys("Spr")
    find("li", text: "Springfield nursery").click

    click_button "Continue"

    expect(page).to have_text "Do you hold one of these teaching qualifications?"
  end

  scenario "not using auto complete - js", js: true do
    create(
      :eligible_eytfi_provider,
      name: "Springfield nursery"
    )

    visit landing_page_path(
      Journeys::EarlyYearsTeachersFinancialIncentivePayments.routing_name
    )

    click_link "Start now"

    expect(page).to have_text "Which nursery do you teach in?"

    find_field("claim[nursery_search_query]").send_keys("Spr")
    find("h1").click # click somewhere else to disimiss the autocomplete dropdown
    click_button "Continue"

    expect(page).to have_text "Which nursery do you teach in?"
    choose("Springfield nursery")
    click_button "Continue"

    expect(page).to have_text "Do you hold one of these teaching qualifications?"
  end

  scenario "no nursseries found" do
    create(
      :eligible_eytfi_provider,
      name: "Springfield nursery"
    )

    visit landing_page_path(
      Journeys::EarlyYearsTeachersFinancialIncentivePayments.routing_name
    )

    click_link "Start now"

    expect(page).to have_text "Which nursery do you teach in?"
    find_field("claim[nursery_search_query]").set("no results for this search")
    click_button "Continue"

    expect(page).to have_content("No results match your search term")

    click_link "search again"

    expect(page).to have_text "Which nursery do you teach in?"
    find_field("claim[nursery_search_query]").set("spring")
    click_button "Continue"

    expect(page).to have_text "Select your nursery from the search results."
    expect(page).to have_selector("label", text: "Springfield nursery")
  end
end
