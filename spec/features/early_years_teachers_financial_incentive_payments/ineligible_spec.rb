require "rails_helper"

# @journey EarlyYearsTeachersFinancialIncentivePayments
RSpec.feature "EYTFI journey ineligible paths", :testing_persona, feature_flag: [:eytfi_journey] do
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
  end

  scenario "ineligible nursery chosen" do
    create(
      :eligible_eytfi_provider,
      name: "Shelbyvile nursery",
      eligible: false
    )

    visit landing_page_path(
      Journeys::EarlyYearsTeachersFinancialIncentivePayments.routing_name
    )
    click_link "Start now"

    expect(page).to have_text "Which nursery do you teach in?"
    find_field("claim[nursery_search_query]").set("Shelbyvile nursery")
    click_button "Continue"

    expect(page).to have_text "Which nursery do you teach in?"
    choose "Shelbyvile nursery"
    click_button "Continue"
    expect(page).to have_text("The nursery you selected may not be eligible")

    expect(page).to have_text(
      "Based on our records, the nursery you selected is not currently eligible for the early years teacher recognition payment."
    )
    click_link "Back"

    expect(page).to have_text "Which nursery do you teach in?"
  end

  scenario "claimant gives the claim a go at an ineligible nursery" do
    create(
      :eligible_eytfi_provider,
      name: "Little Teapots Pre School",
      town: "Bury St Edmunds",
      postcode: "IP29 4UL",
      eligible: false
    )

    visit landing_page_path(
      Journeys::EarlyYearsTeachersFinancialIncentivePayments.routing_name
    )
    click_link "Start now"

    expect(page).to have_text "Which nursery do you teach in?"
    find_field("claim[nursery_search_query]").set("Little Teapots Pre School")
    click_button "Continue"

    expect(page).to have_text "Which nursery do you teach in?"
    choose "Little Teapots Pre School"
    click_button "Continue"
    expect(page).to have_text "The nursery you selected may not be eligible"
  end

  scenario "Anna is unsure whether her nursery is eligible" do
    create(
      :eligible_eytfi_provider,
      name: "Little Teapots Pre School",
      town: "Bury St Edmunds",
      postcode: "IP29 4UL",
      eligible: false
    )

    visit landing_page_path(
      Journeys::EarlyYearsTeachersFinancialIncentivePayments.routing_name
    )
    click_link "Start now"

    expect(page).to have_text "Which nursery do you teach in?"
    find_field("claim[nursery_search_query]").set("Little Teapots Pre School")
    click_button "Continue"

    expect(page).to have_text "Which nursery do you teach in?"
    choose "Little Teapots Pre School"
    click_button "Continue"
    expect(page).to have_text "The nursery you selected may not be eligible"
  end

  scenario "user is eligible but cannot verify their ID via One Login" do
    create(
      :eligible_eytfi_provider,
      name: "Sunflower Nurseries",
      town: "Rochdale",
      postcode: "OL11 2HD"
    )

    visit landing_page_path(
      Journeys::EarlyYearsTeachersFinancialIncentivePayments.routing_name
    )
    click_link "Start now"

    expect(page).to have_text "Which nursery do you teach in?"
    find_field("claim[nursery_search_query]").set("Sunflower Nurseries")
    click_button "Continue"

    expect(page).to have_text "Which nursery do you teach in?"
    choose "Sunflower Nurseries"
    click_button "Continue"
    choose "Yes"
    click_button "Continue"

    expect(page).to have_text "Check if you’re eligible"
    choose "Yes"
    click_button "Confirm and continue"

    expect(page).to have_text "You’re eligible to apply"
    click_button "Continue"

    expect(page).to have_text "Sign in with GOV.UK One Login"
    expect(page).not_to have_text "Is this your National Insurance number?"
  end

  scenario "Anna is ineligible because she is training for an EYTS" do
    create(
      :eligible_eytfi_provider,
      name: "Dimples Stainton Day Nursery",
      town: "Middlesbrough",
      postcode: "TS17 9LW"
    )

    visit landing_page_path(
      Journeys::EarlyYearsTeachersFinancialIncentivePayments.routing_name
    )
    click_link "Start now"

    expect(page).to have_text "Which nursery do you teach in?"
    find_field("claim[nursery_search_query]").set("Dimples Stainton Day Nursery")
    click_button "Continue"

    expect(page).to have_text "Which nursery do you teach in?"
    choose "Dimples Stainton Day Nursery"
    click_button "Continue"
    expect(page).to have_text "Do you hold one of these teaching qualifications?"
    choose "No"
    click_button "Continue"

    expect(page).to have_link "Back", href: "/early-years-teachers-recognition-payments/teaching-qualification-confirmation"
    expect(page).to have_text "You’re not eligible for this payment"
  end

  scenario "Jane exits from One Login before returning to the claim" do
    create(
      :eligible_eytfi_provider,
      name: "Wonderland Children's Day Nursery",
      town: "Rochdale",
      postcode: "OL11 2HD"
    )

    visit landing_page_path(
      Journeys::EarlyYearsTeachersFinancialIncentivePayments.routing_name
    )
    click_link "Start now"

    expect(page).to have_text "Which nursery do you teach in?"
    find_field("claim[nursery_search_query]").set("Wonderland Children's Day Nursery")
    click_button "Continue"

    expect(page).to have_text "Which nursery do you teach in?"
    choose "Wonderland Children's Day Nursery"
    click_button "Continue"
    choose "Yes"
    click_button "Continue"

    expect(page).to have_text "Check if you’re eligible"
    choose "Yes"
    click_button "Confirm and continue"

    expect(page).to have_text "You’re eligible to apply"
    click_button "Continue"

    expect(page).to have_text "Sign in with GOV.UK One Login"
    expect(page).not_to have_text "Is this your national insurance number"
  end

  scenario "Mike cannot find his teacher reference number" do
    create(
      :eligible_eytfi_provider,
      name: "Lostock Playschool",
      town: "Bolton",
      postcode: "BL6 4EL"
    )

    allow(Dqt::Client).to receive(:new).and_return(
      instance_double(
        "Dqt::Client",
        teacher: instance_double(
          "Dqt::TeacherResource",
          find: instance_double(
            "Dqt::Teacher",
            has_eligible_eytfi_qualification?: true,
            national_insurance_number: "AB123456C"
          )
        )
      )
    )

    visit landing_page_path(
      Journeys::EarlyYearsTeachersFinancialIncentivePayments.routing_name
    )
    click_link "Start now"

    expect(page).to have_text "Which nursery do you teach in?"
    find_field("claim[nursery_search_query]").set("Lostock Playschool")
    click_button "Continue"

    expect(page).to have_text "Which nursery do you teach in?"
    choose "Lostock Playschool"
    click_button "Continue"
    choose "Yes"
    click_button "Continue"

    expect(page).to have_text "Check if you’re eligible"
    choose "Yes"
    click_button "Confirm and continue"

    expect(page).to have_text "You’re eligible to apply"
    click_button "Continue"

    expect(page).to have_text "Sign in with GOV.UK One Login"
    perform_enqueued_jobs do
      click_button "Continue"
    end

    expect(page).to have_text "Is this your National Insurance number?"
    expect(page).to have_text "AB123456C"
  end

  scenario "Travis has an ineligible qualification match" do
    create(
      :eligible_eytfi_provider,
      name: "Green Garden Community Nursery",
      town: "West Bromwich",
      postcode: "B70 9JF"
    )

    allow(Dqt::Client).to receive(:new).and_return(
      instance_double(
        "Dqt::Client",
        teacher: instance_double(
          "Dqt::TeacherResource",
          find: instance_double(
            "Dqt::Teacher",
            has_eligible_eytfi_qualification?: false,
            national_insurance_number: nil
          )
        )
      )
    )

    visit landing_page_path(
      Journeys::EarlyYearsTeachersFinancialIncentivePayments.routing_name
    )
    click_link "Start now"

    expect(page).to have_text "Which nursery do you teach in?"
    find_field("claim[nursery_search_query]").set("Green Garden Community Nursery")
    click_button "Continue"

    expect(page).to have_text "Which nursery do you teach in?"
    choose "Green Garden Community Nursery"
    click_button "Continue"
    choose "Yes"
    click_button "Continue"

    expect(page).to have_text "Check if you’re eligible"
    choose "Yes"
    click_button "Confirm and continue"

    expect(page).to have_text "You’re eligible to apply"
    click_button "Continue"

    expect(page).to have_text "Sign in with GOV.UK One Login"
    perform_enqueued_jobs do
      click_button "Continue"
    end

    expect(page).to have_text "You’re not eligible based on your qualification"
    expect(page).not_to have_text "Is this your national insurance number"
  end

  scenario "Glen changes his National Insurance number after a mismatch" do
    create(
      :eligible_eytfi_provider,
      name: "Brighter Bunnies Pre School",
      town: "Bolton",
      postcode: "BL5 2BG"
    )

    allow(Dqt::Client).to receive(:new).and_return(
      instance_double(
        "Dqt::Client",
        teacher: instance_double(
          "Dqt::TeacherResource",
          find: instance_double(
            "Dqt::Teacher",
            has_eligible_eytfi_qualification?: true,
            national_insurance_number: "AB987654C"
          )
        )
      )
    )

    visit landing_page_path(
      Journeys::EarlyYearsTeachersFinancialIncentivePayments.routing_name
    )
    click_link "Start now"

    expect(page).to have_text "Which nursery do you teach in?"
    find_field("claim[nursery_search_query]").set("Brighter Bunnies Pre School")
    click_button "Continue"

    expect(page).to have_text "Which nursery do you teach in?"
    choose "Brighter Bunnies Pre School"
    click_button "Continue"
    choose "Yes"
    click_button "Continue"

    expect(page).to have_text "Check if you’re eligible"
    choose "Yes"
    click_button "Confirm and continue"

    expect(page).to have_text "You’re eligible to apply"
    click_button "Continue"

    expect(page).to have_text "Sign in with GOV.UK One Login"
    perform_enqueued_jobs do
      click_button "Continue"
    end

    expect(page).to have_text "Is this your National Insurance number?"
    choose "No"
    fill_in "What is your National Insurance number?", with: "AB123456C"
    click_button "Continue"

    expect(page).to have_text "Upload your payslip"
    upload_employment_proof

    expect(page).to have_text "You may be eligible for a recognition payment"
  end

  scenario "Susan uploads a payslip after a qualification mismatch" do
    create(
      :eligible_eytfi_provider,
      name: "Sunny Days Nursery",
      town: "London",
      postcode: "EC1N 2TD"
    )

    allow(Dqt::Client).to receive(:new).and_return(
      instance_double(
        "Dqt::Client",
        teacher: instance_double(
          "Dqt::TeacherResource",
          find: instance_double(
            "Dqt::Teacher",
            has_eligible_eytfi_qualification?: true,
            national_insurance_number: "AB987654C"
          )
        )
      )
    )

    visit landing_page_path(
      Journeys::EarlyYearsTeachersFinancialIncentivePayments.routing_name
    )
    click_link "Start now"

    expect(page).to have_text "Which nursery do you teach in?"
    find_field("claim[nursery_search_query]").set("Sunny Days Nursery")
    click_button "Continue"

    expect(page).to have_text "Which nursery do you teach in?"
    choose "Sunny Days Nursery"
    click_button "Continue"
    choose "Yes"
    click_button "Continue"

    expect(page).to have_text "Check if you’re eligible"
    choose "Yes"
    click_button "Confirm and continue"

    expect(page).to have_text "You’re eligible to apply"
    click_button "Continue"

    expect(page).to have_text "Sign in with GOV.UK One Login"
    perform_enqueued_jobs do
      click_button "Continue"
    end

    expect(page).to have_text "Is this your National Insurance number?"
    choose "No"
    fill_in "What is your National Insurance number?", with: "AB123456C"
    click_button "Continue"

    expect(page).to have_text "Upload your payslip"
    attach_file(
      "Upload document",
      Rails.root.join("spec/fixtures/files/employment_proof.pdf")
    )
    click_button "Upload"

    expect(page).to have_text "Check your document"
    choose "Yes, add this file"
    click_button "Continue"

    expect(page).to have_text "You may be eligible for a recognition payment"
  end

  scenario "Barney accidentally declines the claim continuation" do
    create(
      :eligible_eytfi_provider,
      name: "Elm Lane Day Nursery",
      town: "Dagenham",
      postcode: "RM10 9UR"
    )

    allow(Dqt::Client).to receive(:new).and_return(
      instance_double(
        "Dqt::Client",
        teacher: instance_double(
          "Dqt::TeacherResource",
          find: instance_double(
            "Dqt::Teacher",
            has_eligible_eytfi_qualification?: true,
            national_insurance_number: "AB123456C"
          )
        )
      )
    )

    visit landing_page_path(
      Journeys::EarlyYearsTeachersFinancialIncentivePayments.routing_name
    )
    click_link "Start now"

    expect(page).to have_text "Which nursery do you teach in?"
    find_field("claim[nursery_search_query]").set("Elm Lane Day Nursery")
    click_button "Continue"

    expect(page).to have_text "Which nursery do you teach in?"
    choose "Elm Lane Day Nursery"
    click_button "Continue"
    choose "Yes"
    click_button "Continue"

    expect(page).to have_text "Check if you’re eligible"
    choose "Yes"
    click_button "Confirm and continue"

    expect(page).to have_text "You’re eligible to apply"
    click_button "Continue"

    expect(page).to have_text "Sign in with GOV.UK One Login"
    perform_enqueued_jobs do
      click_button "Continue"
    end

    expect(page).to have_text "Is this your National Insurance number?"
    choose "Yes"
    click_button "Continue"

    upload_employment_proof

    expect(page).to have_text "You may be eligible for a recognition payment"
    choose "No"
    click_button "Continue"

    expect(page).to have_text "Claim cancelled"
  end

  scenario "Sara confirms the matching HMRC location and uploads a payslip" do
    create(
      :eligible_eytfi_provider,
      name: "Sunny Days Nursery",
      town: "Weaverham",
      postcode: "EC1N 2TD"
    )

    allow(Dqt::Client).to receive(:new).and_return(
      instance_double(
        "Dqt::Client",
        teacher: instance_double(
          "Dqt::TeacherResource",
          find: instance_double(
            "Dqt::Teacher",
            has_eligible_eytfi_qualification?: true,
            national_insurance_number: "AB123456C"
          )
        )
      )
    )

    visit landing_page_path(
      Journeys::EarlyYearsTeachersFinancialIncentivePayments.routing_name
    )
    click_link "Start now"

    expect(page).to have_text "Which nursery do you teach in?"
    find_field("claim[nursery_search_query]").set("Sunny Days Nursery")
    click_button "Continue"

    expect(page).to have_text "Which nursery do you teach in?"
    choose "Sunny Days Nursery"
    click_button "Continue"
    choose "Yes"
    click_button "Continue"

    expect(page).to have_text "Check if you’re eligible"
    choose "Yes"
    click_button "Confirm and continue"

    expect(page).to have_text "You’re eligible to apply"
    click_button "Continue"

    expect(page).to have_text "Sign in with GOV.UK One Login"
    perform_enqueued_jobs do
      click_button "Continue"
    end

    expect(page).to have_text "Is this your National Insurance number?"
    choose "Yes"
    click_button "Continue"

    expect(page).to have_text "Upload your payslip"
    attach_file(
      "Upload document",
      Rails.root.join("spec/fixtures/files/employment_proof.pdf")
    )
    click_button "Upload"

    expect(page).to have_text "Check your document"
    choose "Yes, add this file"
    click_button "Continue"

    expect(page).to have_text "You may be eligible for a recognition payment"
    choose "Yes"
    click_button "Continue"

    expect(page).to have_title "How we’ll use your information"
    expect(page).to have_text "How we’ll use your information"
    click_button "Continue"

    expect(page).to have_text "What is your home address?"
    click_button "Enter your address manually"

    fill_in "House number or name", with: "Schuster, Kulas and Ward"
    fill_in "Building and street", with: "62530 Emmerich Street, Apt. 469"
    fill_in "Town or city", with: "Pine Pointe"
    fill_in "County", with: "Breitenbergport"
    fill_in "Postcode", with: "EC1N 2TD"
    click_button "Continue"

    expect(page).to have_text(I18n.t("questions.account_details"))
    fill_in "Name on the account", with: "Sara Jones"
    fill_in "Sort code", with: "123456"
    fill_in "Account number", with: "12345678"
    click_button "Continue"

    expect(page).to have_text "Are you recorded as male or female on your employer’s payroll system?"
  end

  scenario "Andy mistakes the document upload success for the claim being complete" do
    create(
      :eligible_eytfi_provider,
      name: "Anston Stones Early Years",
      town: "Sheffield",
      postcode: "S25 2QZ"
    )

    allow(Dqt::Client).to receive(:new).and_return(
      instance_double(
        "Dqt::Client",
        teacher: instance_double(
          "Dqt::TeacherResource",
          find: instance_double(
            "Dqt::Teacher",
            has_eligible_eytfi_qualification?: true,
            national_insurance_number: "AB123456C"
          )
        )
      )
    )

    visit landing_page_path(
      Journeys::EarlyYearsTeachersFinancialIncentivePayments.routing_name
    )
    click_link "Start now"

    expect(page).to have_text "Which nursery do you teach in?"
    find_field("claim[nursery_search_query]").set("Anston Stones Early Years")
    click_button "Continue"

    expect(page).to have_text "Which nursery do you teach in?"
    choose "Anston Stones Early Years"
    click_button "Continue"
    choose "Yes"
    click_button "Continue"

    expect(page).to have_text "Check if you’re eligible"
    choose "Yes"
    click_button "Confirm and continue"

    expect(page).to have_text "You’re eligible to apply"
    click_button "Continue"

    expect(page).to have_text "Sign in with GOV.UK One Login"
    perform_enqueued_jobs do
      click_button "Continue"
    end

    expect(page).to have_text "Is this your National Insurance number?"
    choose "Yes"
    click_button "Continue"

    expect(page).to have_text "Upload your payslip"
    attach_file(
      "Upload document",
      Rails.root.join("spec/fixtures/files/employment_proof.pdf")
    )
    click_button "Upload"

    expect(page).to have_text "Check your document"
    choose "Yes, add this file"
    click_button "Continue"

    expect(page).to have_text "You may be eligible for a recognition payment"
    choose "Yes"
    click_button "Continue"

    expect(page).to have_title "How we’ll use your information"
    expect(page).to have_text "How we’ll use your information"
    click_button "Continue"

    expect(page).to have_text "What is your home address?"
  end

  scenario "Mia cannot find her address in the postcode lookup" do
    create(
      :eligible_eytfi_provider,
      name: "The Avenue Day Nursery",
      town: "Middlesbrough",
      postcode: "TS5 6PA"
    )

    allow(Dqt::Client).to receive(:new).and_return(
      instance_double(
        "Dqt::Client",
        teacher: instance_double(
          "Dqt::TeacherResource",
          find: instance_double(
            "Dqt::Teacher",
            has_eligible_eytfi_qualification?: true,
            national_insurance_number: "AB123456C"
          )
        )
      )
    )

    visit landing_page_path(
      Journeys::EarlyYearsTeachersFinancialIncentivePayments.routing_name
    )
    click_link "Start now"

    expect(page).to have_text "Which nursery do you teach in?"
    find_field("claim[nursery_search_query]").set("The Avenue Day Nursery")
    click_button "Continue"

    expect(page).to have_text "Which nursery do you teach in?"
    choose "The Avenue Day Nursery"
    click_button "Continue"
    choose "Yes"
    click_button "Continue"

    expect(page).to have_text "Check if you’re eligible"
    choose "Yes"
    click_button "Confirm and continue"

    expect(page).to have_text "You’re eligible to apply"
    click_button "Continue"

    expect(page).to have_text "Sign in with GOV.UK One Login"
    perform_enqueued_jobs do
      click_button "Continue"
    end

    expect(page).to have_text "Is this your National Insurance number?"
    choose "Yes"
    click_button "Continue"

    attach_file(
      "Upload document",
      Rails.root.join("spec/fixtures/files/employment_proof.pdf")
    )
    click_button "Upload"

    expect(page).to have_text "Check your document"
    choose "Yes, add this file"
    click_button "Continue"

    expect(page).to have_text "You may be eligible for a recognition payment"
    choose "Yes"
    click_button "Continue"

    expect(page).to have_title "How we’ll use your information"
    expect(page).to have_text "How we’ll use your information"
    click_button "Continue"

    expect(page).to have_text "What is your home address?"

    allow_any_instance_of(OrdnanceSurvey::Client)
      .to receive_message_chain(:api, :search_places, :index)
      .and_return(nil)

    fill_in "Postcode", with: "TS5 6PA"
    click_button "Search"

    expect(page).to have_text "Address not found"
    expect(page).to have_text "Enter your address manually"
    click_button "Enter your address manually"

    fill_in "House number or name", with: "2"
    fill_in "Building and street", with: "Oak Lane"
    fill_in "Town or city", with: "Middlesbrough"
    fill_in "County", with: "North Yorkshire"
    fill_in "Postcode", with: "TS5 6PA"
    click_button "Continue"

    expect(page).to have_text(I18n.t("questions.account_details"))
    fill_in "Name on the account", with: "Mia Johnson"
    fill_in "Sort code", with: "123456"
    fill_in "Account number", with: "12345678"
    click_button "Continue"

    expect(page).to have_text "Are you recorded as male or female on your employer’s payroll system?"
  end

  context "when HMRC rejects the account number", :with_hmrc_bank_validation_enabled, :with_stubbed_hmrc_client do
    include_examples "stub_teacher_auth"
    let(:account_exists) { false }

    scenario "Michael cannot enter his bank details" do
      create(
        :eligible_eytfi_provider,
        name: "Barking Riverside Nursery School",
        address_line_1: "Renwick Road",
        town: "Barking",
        postcode: "IG11 0FU"
      )

      visit landing_page_path(
        Journeys::EarlyYearsTeachersFinancialIncentivePayments.routing_name
      )

      click_link "Start now"

      expect(page).to have_text "Which nursery do you teach in?"
      find_field("claim[nursery_search_query]").set("Barking Riverside Nursery School")
      click_button "Continue"

      expect(page).to have_text "Which nursery do you teach in?"
      choose "Barking Riverside Nursery School"
      click_button "Continue"

      expect(page).to have_text "Do you hold one of these teaching qualifications?"
      choose "Yes"
      click_button "Continue"

      expect(page).to have_text "Check if you’re eligible"
      choose "Yes"
      click_button "Confirm and continue"

      expect(page).to have_text "You’re eligible to apply"
      click_button "Continue"

      expect(page).to have_text "Sign in with GOV.UK One Login"
      perform_enqueued_jobs do
        click_button "Continue"
      end

      expect(page).to have_text "Enter your National Insurance number"
      fill_in "Enter your National Insurance number", with: "AB123456C"
      click_button "Continue"

      upload_employment_proof

      expect(page).to have_text "You may be eligible for a recognition payment"
      choose "Yes"
      click_button "Continue"

      expect(page).to have_title "How we’ll use your information"
      expect(page).to have_text "How we’ll use your information"
      click_button "Continue"

      expect(page).to have_text "What is your home address?"
      click_button "Enter your address manually"

      fill_in "House number or name", with: "18"
      fill_in "Building and street", with: "Renwick Road"
      fill_in "Town or city", with: "Barking"
      fill_in "County", with: "Essex"
      fill_in "Postcode", with: "IG11 0FU"
      click_button "Continue"

      expect(page).to have_text(I18n.t("questions.account_details"))
      fill_in "Name on the account", with: "Michael Smith"
      fill_in "Sort code", with: "123456"
      fill_in "Account number", with: "1234567"
      click_button "Continue"

      expect(page).to have_text "Account number must be 8 digits"

      fill_in "Account number", with: "12345678"
      click_button "Continue"

      expect(page).to have_text "Enter the account number associated with the name on the account and/or sort code"
    end
  end

  scenario "Maureen does not select her gender" do
    create(
      :eligible_eytfi_provider,
      name: "Willow Green Day Nursery",
      address_line_1: "Heanor Avenue",
      town: "Denton",
      postcode: "M34 7WU"
    )

    allow(Dqt::Client).to receive(:new).and_return(
      instance_double(
        "Dqt::Client",
        teacher: instance_double(
          "Dqt::TeacherResource",
          find: instance_double(
            "Dqt::Teacher",
            has_eligible_eytfi_qualification?: true,
            national_insurance_number: nil
          )
        )
      )
    )

    visit landing_page_path(
      Journeys::EarlyYearsTeachersFinancialIncentivePayments.routing_name
    )
    click_link "Start now"

    expect(page).to have_text "Which nursery do you teach in?"
    find_field("claim[nursery_search_query]").set("Willow Green Day Nursery")
    click_button "Continue"

    expect(page).to have_text "Which nursery do you teach in?"
    choose "Willow Green Day Nursery"
    click_button "Continue"
    choose "Yes"
    click_button "Continue"

    expect(page).to have_text "Check if you’re eligible"
    choose "Yes"
    click_button "Confirm and continue"

    expect(page).to have_text "You’re eligible to apply"
    click_button "Continue"

    expect(page).to have_text "Sign in with GOV.UK One Login"
    perform_enqueued_jobs do
      click_button "Continue"
    end

    expect(page).to have_text "Enter your National Insurance number"
    fill_in "Enter your National Insurance number", with: "AB123456C"
    click_button "Continue"

    upload_employment_proof

    expect(page).to have_text "You may be eligible for a recognition payment"
    choose "Yes"
    click_button "Continue"

    expect(page).to have_title "How we’ll use your information"
    expect(page).to have_text "How we’ll use your information"
    click_button "Continue"

    expect(page).to have_text "What is your home address?"
    click_button "Enter your address manually"

    fill_in "House number or name", with: "25"
    fill_in "Building and street", with: "Heanor Avenue"
    fill_in "Town or city", with: "Denton"
    fill_in "County", with: "Greater Manchester"
    fill_in "Postcode", with: "M34 7WU"
    click_button "Continue"

    expect(page).to have_text(I18n.t("questions.account_details"))
    fill_in "Name on the account", with: "Maureen Smith"
    fill_in "Sort code", with: "123456"
    fill_in "Account number", with: "12345678"
    click_button "Continue"

    expect(page).to have_text "Are you recorded as male or female on your employer’s payroll system?"
    click_button "Continue"

    expect(page).to have_text "Are you recorded as male or female on your employer’s payroll system?"
  end

  scenario "claimant states they do not have relevant qualification" do
    create(
      :eligible_eytfi_provider,
      name: "Springfield nursery"
    )

    visit landing_page_path(Journeys::EarlyYearsTeachersFinancialIncentivePayments.routing_name)
    click_link "Start now"

    expect(page).to have_text "Which nursery do you teach in?"
    find_field("claim[nursery_search_query]").set("Springfield nursery")
    click_button "Continue"

    expect(page).to have_text "Which nursery do you teach in?"
    choose "Springfield nursery"
    click_button "Continue"

    expect(page).to have_text "Do you hold one of these teaching qualifications?"
    choose "No"
    click_button "Continue"

    expect(page).to have_link "Back", href: "/early-years-teachers-recognition-payments/teaching-qualification-confirmation"
    expect(page).to have_text "You’re not eligible for this payment"
  end

  context do
    include_examples "stub_teacher_auth_with_ineligible_qualification"

    scenario "claimant does not have eligible qualification from TRS lookup" do
      create(
        :eligible_eytfi_provider,
        name: "Springfield nursery"
      )

      visit landing_page_path(Journeys::EarlyYearsTeachersFinancialIncentivePayments.routing_name)
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

      expect(page).to have_text "Check if you’re eligible"
      choose "Yes"
      click_button "Confirm and continue"

      expect(page).to have_text "You’re eligible to apply"
      click_button "Continue"

      expect(page).to have_text "Sign in with GOV.UK One Login"
      perform_enqueued_jobs do
        click_button "Continue"
      end

      expect(page).to have_text "not eligible"
    end
  end

  context do
    include_examples "stub_teacher_auth"

    scenario "claimant rejects payment" do
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

      expect(page).to have_text "Check if you’re eligible"
      choose "Yes"
      click_button "Confirm and continue"

      expect(page).to have_text "You’re eligible to apply"
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

      expect(page).to have_text "Enter your National Insurance number"
      fill_in "Enter your National Insurance number", with: "AB123456C"
      click_button "Continue"

      upload_employment_proof

      expect(page).to have_text "You may be eligible for a recognition payment"
      choose "No"
      click_button "Continue"

      expect(page).to have_text "Claim cancelled"
      click_on "Start a new claim"

      expect(page).to have_text "Start now"
    end
  end

  context do
    include_examples "stub_teacher_auth"

    scenario "Tom misses the confirmation checkbox" do
      create(
        :eligible_eytfi_provider,
        name: "Early Steps Dudley",
        address_line_1: "Bank Road",
        town: "Dudley",
        postcode: "DY3 2NT"
      )

      visit landing_page_path(
        Journeys::EarlyYearsTeachersFinancialIncentivePayments.routing_name
      )

      click_link "Start now"

      expect(page).to have_text "Which nursery do you teach in?"
      find_field("claim[nursery_search_query]").set("Early Steps Dudley")
      click_button "Continue"

      expect(page).to have_text "Which nursery do you teach in?"
      choose "Early Steps Dudley"
      click_button "Continue"

      expect(page).to have_text "Do you hold one of these teaching qualifications?"
      choose "Yes"
      click_button "Continue"

      expect(page).to have_text "Check if you’re eligible"
      choose "Yes"
      click_button "Confirm and continue"

      expect(page).to have_text "You’re eligible to apply"
      click_button "Continue"

      expect(page).to have_text "Sign in with GOV.UK One Login"
      perform_enqueued_jobs do
        click_button "Continue"
      end

      expect(page).to have_text "Enter your National Insurance number"
      fill_in "Enter your National Insurance number", with: "AB123456C"
      click_button "Continue"

      upload_employment_proof

      expect(page).to have_text "You may be eligible for a recognition payment"
      choose "Yes"
      click_button "Continue"

      expect(page).to have_title "How we’ll use your information"
      expect(page).to have_text "How we’ll use your information"
      click_button "Continue"

      expect(page).to have_text "What is your home address?"
      click_button "Enter your address manually"

      fill_in "House number or name", with: "17"
      fill_in "Building and street", with: "Bank Road"
      fill_in "Town or city", with: "Dudley"
      fill_in "County", with: "West Midlands"
      fill_in "Postcode", with: "DY3 2NT"
      click_button "Continue"

      expect(page).to have_text(I18n.t("questions.account_details"))
      fill_in "Name on the account", with: "Tom Jordan"
      fill_in "Sort code", with: "123456"
      fill_in "Account number", with: "12345678"
      click_button "Continue"

      expect(page).to have_text "Are you recorded as male or female on your employer’s payroll system?"
      choose "I don’t know"
      click_button "Continue"

      expect(page).to have_text "Confirm your details and complete your claim"
      click_button "Confirm and claim"

      expect(page).to have_text "Tick the box to confirm that the information provided in this form is correct to the best of your knowledge"
    end

    scenario "Diana does not receive a confirmation email" do
      OmniAuth.config.mock_auth[:teacher] = OmniAuth::AuthHash.new({
        provider: "teacher",
        extra: {
          raw_info: {
            sub: "urn:fdc:gov.uk:2022:#{SecureRandom.base64(30)}",
            trn: "1234567",
            email: "diana.one-login@example.com",
            verified_name: ["Diana", "Jones"],
            verified_date_of_birth: "1970-12-13"
          }
        }
      })

      allow(Dqt::Client).to receive(:new).and_return(
        instance_double(
          "Dqt::Client",
          teacher: instance_double(
            "Dqt::TeacherResource",
            find: instance_double(
              "Dqt::Teacher",
              has_eligible_eytfi_qualification?: true,
              national_insurance_number: nil
            )
          )
        )
      )

      create(
        :eligible_eytfi_provider,
        name: "West Melton Early Years",
        town: "Rotherham",
        postcode: "S63 6NF"
      )

      visit landing_page_path(
        Journeys::EarlyYearsTeachersFinancialIncentivePayments.routing_name
      )

      click_link "Start now"

      expect(page).to have_text "Which nursery do you teach in?"
      find_field("claim[nursery_search_query]").set("West Melton Early Years")
      click_button "Continue"

      expect(page).to have_text "Which nursery do you teach in?"
      choose "West Melton Early Years"
      click_button "Continue"

      expect(page).to have_text "Do you hold one of these teaching qualifications?"
      choose "Yes"
      click_button "Continue"

      expect(page).to have_text "Check if you’re eligible"
      choose "Yes"
      click_button "Confirm and continue"

      expect(page).to have_text "You’re eligible to apply"
      click_button "Continue"

      expect(page).to have_text "Sign in with GOV.UK One Login"
      perform_enqueued_jobs do
        click_button "Continue"
      end

      expect(page).to have_text "Enter your National Insurance number"
      fill_in "Enter your National Insurance number", with: "AB123456C"
      click_button "Continue"

      upload_employment_proof

      expect(page).to have_text "You may be eligible for a recognition payment"
      choose "Yes"
      click_button "Continue"

      expect(page).to have_title "How we’ll use your information"
      expect(page).to have_text "How we’ll use your information"
      click_button "Continue"

      expect(page).to have_text "What is your home address?"
      click_button "Enter your address manually"

      fill_in "House number or name", with: "8"
      fill_in "Building and street", with: "Rotherham Road"
      fill_in "Town or city", with: "Rotherham"
      fill_in "County", with: "South Yorkshire"
      fill_in "Postcode", with: "S63 6NF"
      click_button "Continue"

      expect(page).to have_text(I18n.t("questions.account_details"))
      fill_in "Name on the account", with: "Diana Jones"
      fill_in "Sort code", with: "123456"
      fill_in "Account number", with: "12345678"
      click_button "Continue"

      expect(page).to have_text "Are you recorded as male or female on your employer’s payroll system?"
      choose "I don’t know"
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
      expect(claim.eligibility.teacher_auth_email).to eql("diana.one-login@example.com")

      mail = ActionMailer::Base.deliveries.last
      expect(mail.to).to include("diana.one-login@example.com")
    end

    scenario "double submission" do
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

      expect(page).to have_text "Check if you’re eligible"
      choose "Yes"
      click_button "Confirm and continue"

      expect(page).to have_text "You’re eligible to apply"
      click_button "Continue"

      expect(page).to have_text "Sign in with GOV.UK One Login"
      perform_enqueued_jobs do
        click_button "Continue"
      end

      expect(page).to have_text "Enter your National Insurance number"
      fill_in "Enter your National Insurance number", with: "AB123456C"
      click_button "Continue"

      upload_employment_proof

      expect(page).to have_text "You may be eligible for a recognition payment"
      choose "Yes"
      click_button "Continue"

      expect(page).to have_title "How we’ll use your information"
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

      expect(page).to have_text(I18n.t("questions.account_details"))
      fill_in "Name on the account", with: "John Doe"
      fill_in "Sort code", with: "123456"
      fill_in "Account number", with: "12345678"
      click_button "Continue"

      expect(page).to have_text "Are you recorded as male or female on your employer’s payroll system?"
      choose "I don’t know"
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

      expect(page).to have_text "Your reference number"
      expect(page).to have_text claim.reference

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

      expect(page).to have_text "Check if you’re eligible"
      choose "Yes"
      click_button "Confirm and continue"

      expect(page).to have_text "You’re eligible to apply"
      click_button "Continue"

      expect(page).to have_text "Sign in with GOV.UK One Login"
      perform_enqueued_jobs do
        click_button "Continue"
      end

      expect(page).to have_text "You’ve already submitted a claim in this claim window"
      expect(page).to have_text claim.reference
    end
  end
end
