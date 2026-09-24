require "rails_helper"

RSpec.feature "EYTFI journey", feature_flag: [:eytfi_journey] do
  let(:mock_teacher) do
    instance_double(
      "Dqt::Teacher",
      has_eligible_eytfi_qualification?: true,
      national_insurance_number: "AB123456C"
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
    FeatureFlag.enable!(:eytrp_hmrc_integration)

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

  context "When claimant changes school after HMRC employment check" do
    it "requires the claimant to upload employment proof" do
      employment_history = double(
        "Hmrc::EmploymentHistory",
        request!: nil,
        request_successful?: true,
        employments: [
          {
            startDate: "2026-01-01",
            endDate: nil,
            payFrequency: "MONTHLY",
            employer: {
              name: "Springfield nursery",
              payeReference: "247/A1987CB",
              address: {
                line1: "Unit 23",
                line2: "Utilitarian Industrial Park",
                line3: "Utilitown",
                line4: "County Durham",
                line5: "UK",
                postcode: "DH4 4YY"
              }
            },
            payment: [
              {
                date: "2026-01-31",
                paidTaxablePay: 4765.32
              }
            ]
          }
        ]
      )
      allow(Hmrc::EmploymentHistory).to receive(:new) { employment_history }

      create(:eligible_eytfi_provider, name: "Springfield nursery")

      create(:eligible_eytfi_provider, name: "Secondary nursery")

      visit landing_page_path(
        journey: Journeys::EarlyYearsTeachersFinancialIncentivePayments.routing_name
      )

      click_link "Start now"

      expect(page).to have_text "Which nursery do you teach in?"
      find_field("claim[nursery_search_query]").set("Springfield nursery")
      click_button "Continue"

      expect(page).to have_text "Which nursery do you teach in?"
      choose "Springfield nursery"
      click_button "Continue"

      expect(page).to have_text(
        "Do you hold one of these teaching qualifications?"
      )
      choose "Yes"
      click_button "Continue"

      expect(page).to have_text "Check if you’re eligible"
      check "I spend at least half"
      check "I’m not currently subject"
      click_button "Confirm and continue"

      expect(page).to have_text "You’re eligible to apply"
      click_button "Continue"

      expect(page).to have_text "Sign in with GOV.UK One Login"
      perform_enqueued_jobs do
        click_button "Continue"
      end

      expect(page).to have_content("Is this your National Insurance number?")
      expect(page).to have_content "AB123456C"
      choose "Yes"
      click_button "Continue"

      expect(page).to have_content "Loading"
      perform_enqueued_jobs
      visit current_path # save waiting for the page to reload

      expect(page).to have_text "You may be eligible for a recognition payment"

      choose "Yes"
      click_button "Continue"

      expect(page).to have_text "What is your home address?"
      click_button "Enter your address manually"

      fill_in "House number or name", with: "1"
      fill_in "Building and street", with: "Grey Street"
      fill_in "Town or city", with: "Newcastle upon Tyne"
      fill_in "County", with: "Tyne and Wear"
      fill_in "Postcode", with: "NE1 6EE"
      click_button "Continue"

      expect(page).to have_text(
        "Are you recorded as male or female on your employer’s payroll system?"
      )
      choose "I don’t know"
      click_button "Continue"

      expect(page).to have_text(I18n.t("questions.account_details"))
      fill_in "Name on the account", with: "John Doe"
      fill_in "Sort code", with: "123456"
      fill_in "Account number", with: "12345678"
      click_button "Continue"

      expect(page).to have_text "Confirm your details and complete your claim"
      # Change the nursery to re check employment
      click_on "Change nursery", visible: :all

      expect(page).to have_text "Which nursery do you teach in?"
      find_field("claim[nursery_search_query]").set("Secondary nursery")
      click_button "Continue"

      expect(page).to have_text "Which nursery do you teach in?"
      choose "Secondary nursery"
      click_button "Continue"

      expect(page).to have_content(
        "We could not confirm that you work at the nursery you selected"
      )
      expect(page).to have_content(
        "You selected Secondary nursery as your workplace"
      )
      expect(page).to have_content "Upload document"
      attach_file(
        "Upload document",
        Rails.root.join("spec/fixtures/files/employment_proof.pdf")
      )
      click_button "Upload"

      expect(page).to have_content "Check your document"
      choose "Yes, add this file"
      click_button "Continue"

      expect(page).to have_text "Confirm your details and complete your claim"
    end
  end

  context "When the claimant changes NINO after HMRC check" do
    it "rechecks the employment with HMRC" do
      employment_history = double(
        "Hmrc::EmploymentHistory",
        request!: nil,
        request_successful?: true,
        employments: [
          {
            startDate: "2026-01-01",
            endDate: nil,
            payFrequency: "MONTHLY",
            employer: {
              name: "Springfield nursery",
              payeReference: "247/A1987CB",
              address: {
                line1: "Unit 23",
                line2: "Utilitarian Industrial Park",
                line3: "Utilitown",
                line4: "County Durham",
                line5: "UK",
                postcode: "DH4 4YY"
              }
            },
            payment: [
              {
                date: "2026-01-31",
                paidTaxablePay: 4765.32
              }
            ]
          }
        ]
      )
      allow(Hmrc::EmploymentHistory).to receive(:new) { employment_history }

      create(:eligible_eytfi_provider, name: "Springfield nursery")

      visit landing_page_path(
        journey: Journeys::EarlyYearsTeachersFinancialIncentivePayments.routing_name
      )

      click_link "Start now"

      expect(page).to have_text "Which nursery do you teach in?"
      find_field("claim[nursery_search_query]").set("Springfield nursery")
      click_button "Continue"

      expect(page).to have_text "Which nursery do you teach in?"
      choose "Springfield nursery"
      click_button "Continue"

      expect(page).to have_text(
        "Do you hold one of these teaching qualifications?"
      )
      choose "Yes"
      click_button "Continue"

      expect(page).to have_text "Check if you’re eligible"
      check "I spend at least half"
      check "I’m not currently subject"
      click_button "Confirm and continue"

      expect(page).to have_text "You’re eligible to apply"
      click_button "Continue"

      expect(page).to have_text "Sign in with GOV.UK One Login"
      perform_enqueued_jobs do
        click_button "Continue"
      end

      expect(page).to have_content("Is this your National Insurance number?")
      expect(page).to have_content "AB123456C"
      choose "Yes"
      click_button "Continue"

      expect(page).to have_content "Loading"
      perform_enqueued_jobs
      visit current_path # save waiting for the page to reload

      expect(Hmrc::EmploymentHistory).to have_received(:new).with(
        full_name: "John Doe",
        date_of_birth: Date.new(1970, 12, 13),
        national_insurance_number: "AB123456C"
      )

      expect(page).to have_text "You may be eligible for a recognition payment"

      choose "Yes"
      click_button "Continue"

      expect(page).to have_text "What is your home address?"
      click_button "Enter your address manually"

      fill_in "House number or name", with: "1"
      fill_in "Building and street", with: "Grey Street"
      fill_in "Town or city", with: "Newcastle upon Tyne"
      fill_in "County", with: "Tyne and Wear"
      fill_in "Postcode", with: "NE1 6EE"
      click_button "Continue"

      expect(page).to have_text(
        "Are you recorded as male or female on your employer’s payroll system?"
      )
      choose "I don’t know"
      click_button "Continue"

      expect(page).to have_text(I18n.t("questions.account_details"))
      fill_in "Name on the account", with: "John Doe"
      fill_in "Sort code", with: "123456"
      fill_in "Account number", with: "12345678"
      click_button "Continue"

      expect(page).to have_text "Confirm your details and complete your claim"
      # Change NINO to recheck employment
      click_on "Change national insurance number", visible: :all

      expect(page).to have_content("Is this your National Insurance number?")
      expect(page).to have_content "AB123456C"
      choose "No"
      fill_in "National Insurance number", with: "BB123456C"
      click_button "Continue"

      expect(page).to have_content "Loading"

      # Stub request to hmrc with the new NINO to return nothing
      employment_history = double(
        "Hmrc::EmploymentHistory",
        request!: nil,
        request_successful?: true,
        employments: []
      )
      allow(Hmrc::EmploymentHistory).to receive(:new) { employment_history }

      perform_enqueued_jobs
      visit current_path # save waiting for the page to reload

      expect(Hmrc::EmploymentHistory).to have_received(:new).with(
        full_name: "John Doe",
        date_of_birth: Date.new(1970, 12, 13),
        national_insurance_number: "BB123456C"
      )

      expect(page).to have_content(
        "We could not confirm that you work at the nursery you selected"
      )
      expect(page).to have_content(
        "You selected Springfield nursery as your workplace"
      )
      expect(page).to have_content "Upload document"
      attach_file(
        "Upload document",
        Rails.root.join("spec/fixtures/files/employment_proof.pdf")
      )
      click_button "Upload"

      expect(page).to have_content "Check your document"
      choose "Yes, add this file"
      click_button "Continue"

      expect(page).to have_text "You may be eligible for a recognition payment"
      choose "Yes"
      click_button "Continue"

      expect(page).to have_text "Confirm your details and complete your claim"
    end
  end
end
