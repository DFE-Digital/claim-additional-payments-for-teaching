require "rails_helper"

RSpec.feature "TargetedRetentionIncentivePayments addres", slow: true do
  let!(:journey_configuration) { create(:journey_configuration, :targeted_retention_incentive_payments, current_academic_year: AcademicYear.new(2022)) }
  let(:current_academic_year) { journey_configuration.current_academic_year }

  let(:itt_year) { current_academic_year - 3 }

  context "When auto-populating address details" do
    before do
      body = <<-RESULTS
        {
          "header" : {
            "uri" : "https://api.os.uk/search/places/v1/postcode?postcode=SO169FX",
            "query" : "postcode=SO169FX",
            "offset" : 0,
            "totalresults" : 50,
            "format" : "JSON",
            "dataset" : "DPA",
            "lr" : "EN,CY",
            "maxresults" : 100,
            "epoch" : "85",
            "output_srs" : "EPSG:27700"
          },
          "results" : [
            {
              "DPA" : {
                "UPRN" : "100062039919",
                "UDPRN" : "22785699",
                "ADDRESS" : "FLAT 1, MILLBROOK TOWER, WINDERMERE AVENUE, SOUTHAMPTON, SO16 9FX",
                "SUB_BUILDING_NAME" : "FLAT 1",
                "BUILDING_NAME" : "MILLBROOK TOWER",
                "THOROUGHFARE_NAME" : "WINDERMERE AVENUE",
                "POST_TOWN" : "SOUTHAMPTON",
                "POSTCODE" : "SO16 9FX",
                "RPC" : "2",
                "X_COORDINATE" : 438092.0,
                "Y_COORDINATE" : 114637.0,
                "STATUS" : "APPROVED",
                "LOGICAL_STATUS_CODE" : "1",
                "CLASSIFICATION_CODE" : "RD06",
                "CLASSIFICATION_CODE_DESCRIPTION" : "Self Contained Flat (Includes Maisonette / Apartment)",
                "LOCAL_CUSTODIAN_CODE" : 1780,
                "LOCAL_CUSTODIAN_CODE_DESCRIPTION" : "SOUTHAMPTON",
                "POSTAL_ADDRESS_CODE" : "D",
                "POSTAL_ADDRESS_CODE_DESCRIPTION" : "A record which is linked to PAF",
                "BLPU_STATE_CODE" : "2",
                "BLPU_STATE_CODE_DESCRIPTION" : "In use",
                "TOPOGRAPHY_LAYER_TOID" : "osgb1000016364569",
                "PARENT_UPRN" : "100062691379",
                "LAST_UPDATE_DATE" : "12/11/2018",
                "ENTRY_DATE" : "03/05/2001",
                "BLPU_STATE_DATE" : "11/12/2007",
                "LANGUAGE" : "EN",
                "MATCH" : 1.0,
                "MATCH_DESCRIPTION" : "EXACT"
              }
            },
            {
              "DPA" : {
                "UPRN" : "100062039928",
                "UDPRN" : "22785700",
                "ADDRESS" : "FLAT 10, MILLBROOK TOWER, WINDERMERE AVENUE, SOUTHAMPTON, SO16 9FX",
                "SUB_BUILDING_NAME" : "FLAT 10",
                "BUILDING_NAME" : "MILLBROOK TOWER",
                "THOROUGHFARE_NAME" : "WINDERMERE AVENUE",
                "POST_TOWN" : "SOUTHAMPTON",
                "POSTCODE" : "SO16 9FX",
                "RPC" : "2",
                "X_COORDINATE" : 438092.0,
                "Y_COORDINATE" : 114637.0,
                "STATUS" : "APPROVED",
                "LOGICAL_STATUS_CODE" : "1",
                "CLASSIFICATION_CODE" : "RD06",
                "CLASSIFICATION_CODE_DESCRIPTION" : "Self Contained Flat (Includes Maisonette / Apartment)",
                "LOCAL_CUSTODIAN_CODE" : 1780,
                "LOCAL_CUSTODIAN_CODE_DESCRIPTION" : "SOUTHAMPTON",
                "POSTAL_ADDRESS_CODE" : "D",
                "POSTAL_ADDRESS_CODE_DESCRIPTION" : "A record which is linked to PAF",
                "BLPU_STATE_CODE" : "2",
                "BLPU_STATE_CODE_DESCRIPTION" : "In use",
                "TOPOGRAPHY_LAYER_TOID" : "osgb1000016364569",
                "PARENT_UPRN" : "100062691379",
                "LAST_UPDATE_DATE" : "12/11/2018",
                "ENTRY_DATE" : "03/05/2001",
                "BLPU_STATE_DATE" : "11/12/2007",
                "LANGUAGE" : "EN",
                "MATCH" : 1.0,
                "MATCH_DESCRIPTION" : "EXACT"
              }
            },
            {
              "DPA" : {
                "UPRN" : "100062039929",
                "UDPRN" : "22785701",
                "ADDRESS" : "FLAT 11, MILLBROOK TOWER, WINDERMERE AVENUE, SOUTHAMPTON, SO16 9FX",
                "SUB_BUILDING_NAME" : "FLAT 11",
                "BUILDING_NAME" : "MILLBROOK TOWER",
                "THOROUGHFARE_NAME" : "WINDERMERE AVENUE",
                "POST_TOWN" : "SOUTHAMPTON",
                "POSTCODE" : "SO16 9FX",
                "RPC" : "2",
                "X_COORDINATE" : 438092.0,
                "Y_COORDINATE" : 114637.0,
                "STATUS" : "APPROVED",
                "LOGICAL_STATUS_CODE" : "1",
                "CLASSIFICATION_CODE" : "RD06",
                "CLASSIFICATION_CODE_DESCRIPTION" : "Self Contained Flat (Includes Maisonette / Apartment)",
                "LOCAL_CUSTODIAN_CODE" : 1780,
                "LOCAL_CUSTODIAN_CODE_DESCRIPTION" : "SOUTHAMPTON",
                "POSTAL_ADDRESS_CODE" : "D",
                "POSTAL_ADDRESS_CODE_DESCRIPTION" : "A record which is linked to PAF",
                "BLPU_STATE_CODE" : "2",
                "BLPU_STATE_CODE_DESCRIPTION" : "In use",
                "TOPOGRAPHY_LAYER_TOID" : "osgb1000016364569",
                "PARENT_UPRN" : "100062691379",
                "LAST_UPDATE_DATE" : "12/11/2018",
                "ENTRY_DATE" : "03/05/2001",
                "BLPU_STATE_DATE" : "11/12/2007",
                "LANGUAGE" : "EN",
                "MATCH" : 1.0,
                "MATCH_DESCRIPTION" : "EXACT"
              }
            }
          ]
        }
      RESULTS

      stub_request(:get, "https://api.os.uk/search/places/v1/postcode?key=api-key-value&postcode=SO169FX")
        .with(
          headers: {
            "Content-Type" => "application/json",
            "User-Agent" => "Faraday v#{Faraday::VERSION}"
          }
        ).to_return(status: 200, body: body, headers: {})
    end

    let(:journey_session) do
      visit new_claim_path(Journeys::TargetedRetentionIncentivePayments.routing_name)
      session = Journeys::TargetedRetentionIncentivePayments::Session.last
      session.answers.assign_attributes(
        attributes_for(
          :targeted_retention_incentive_payments_answers,
          :targeted_retention_incentive_eligible
        )
      )
      session.save!
      session
    end

    scenario "with Ordnance Survey data" do
      jump_to_claim_journey_page(
        slug: "check-your-answers-part-one",
        journey_session:
      )

      # - Check your answers for eligibility
      expect(page).to have_text("Check your answers")
      expect(page).to have_text("Eligibility details")
      expect(page).to have_text("By selecting continue you are confirming that, to the best of your knowledge, the details you are providing are correct.")

      %w[Identity\ details Payment\ details].each do |section_heading|
        expect(page).not_to have_text section_heading
      end

      click_on("Continue")

      # - You are eligible for a targeted retention incentive payment
      expect(page).to have_text("You’re eligible for a targeted retention incentive payment")
      click_on "Apply now"

      # - How will we use the information you provide
      expect(page).to have_text("How we will use the information you provide")
      click_on "Continue"

      # - Personal details
      expect(page).to have_text("Personal details")
      expect(page).to have_text("What is your full name?")

      fill_in "First name", with: "Russell"
      fill_in "Last name", with: "Wong"

      expect(page).to have_text("What is your date of birth?")

      fill_in "Day", with: "28"
      fill_in "Month", with: "2"
      fill_in "Year", with: "1988"

      expect(page).to have_text("What is your National Insurance number?")

      fill_in "National Insurance number", with: "PX321499A"
      click_on "Continue"

      # - What is your home address
      expect(page).to have_text("What is your home address?")
      expect(page).to have_button("Enter your address manually")

      fill_in "Postcode", with: "SO16 9FX"
      click_on "Search"

      # - Select your home address
      expect(page).to have_text("What is your home address?")

      choose "Flat 11, Millbrook Tower, Windermere Avenue, Southampton, SO16 9FX"
      click_on "Continue"

      # - What is your address
      expect(page).not_to have_text("What is your address?")

      # - Email address
      expect(page).to have_text("Email address")

      fill_in "Email address", with: "david.tau1988@hotmail.co.uk"
      click_on "Continue"

      # - One time password
      expect(page).to have_text("Email address verification")
      expect(page).to have_text("Enter the 6-digit passcode")

      mail = ActionMailer::Base.deliveries.last
      otp_in_mail_sent = mail.personalisation[:one_time_password]

      fill_in "claim-one-time-password-field", with: otp_in_mail_sent
      click_on "Confirm"

      # - Provide mobile number
      expect(page).to have_text("Would you like to provide your mobile number?")

      choose "No"
      click_on "Continue"

      # - Mobile number
      expect(page).not_to have_text("Mobile number")

      # - Mobile number one-time password
      expect(page).not_to have_text("Enter the 6-digit passcode")

      # - Enter bank account details
      expect(page).to have_text("Enter your personal bank account details")

      fill_in "Name on your account", with: "Jo Bloggs"
      fill_in "Sort code", with: "123456"
      fill_in "Account number", with: "87654321"
      click_on "Continue"

      # - What gender does your school's payroll system associate with you
      expect(page).to have_text("How is your gender recorded on your school’s payroll system?")

      choose "Female"
      click_on "Continue"

      # - What is your teacher reference number
      expect(page).to have_text("What is your teacher reference number (TRN)?")

      fill_in "claim-teacher-reference-number-field", with: "1234567"
      click_on "Continue"

      # - Check your answers before sending your application
      expect(page).to have_text("Check your answers before sending your application")
      expect(page).not_to have_text("Eligibility details")
      %w[Identity\ details Payment\ details].each do |section_heading|
        expect(page).to have_text section_heading
      end

      freeze_time do
        click_on "Accept and send"

        expect(Claim.count).to eq 1
        submitted_claim = Claim.by_policy(Policies::TargetedRetentionIncentivePayments).order(:created_at).last
        expect(submitted_claim.first_name).to eql("Russell")
        expect(submitted_claim.surname).to eql("Wong")
        expect(submitted_claim.date_of_birth).to eq(Date.new(1988, 2, 28))
        expect(submitted_claim.national_insurance_number).to eq("PX321499A")
        expect(submitted_claim.address_line_1).to eql "Flat 11, Millbrook Tower"
        expect(submitted_claim.address_line_2).to eql "Windermere Avenue"
        expect(submitted_claim.address_line_3).to eql "Southampton"
        expect(submitted_claim.postcode).to eql "SO16 9FX"
        expect(submitted_claim.email_address).to eql("david.tau1988@hotmail.co.uk")
        expect(submitted_claim.provide_mobile_number).to eql false
        expect(submitted_claim.banking_name).to eq("Jo Bloggs")
        expect(submitted_claim.bank_sort_code).to eq("123456")
        expect(submitted_claim.bank_account_number).to eq("87654321")
        expect(submitted_claim.payroll_gender).to eq("female")
        expect(submitted_claim.eligibility.teacher_reference_number).to eql("1234567")
        expect(submitted_claim.submitted_at).to eq(Time.zone.now)

        # - Application complete (make sure its Word for Word and styling matches)
        expect(page).to have_text("You applied for a targeted retention incentive payment")
        expect(page).to have_text("What happens next")
        expect(page).to have_text("Set a reminder to apply next year")
        expect(page).to have_text("What do you think of this service?")
        expect(page).to have_text(submitted_claim.reference)
      end
    end
  end
end
