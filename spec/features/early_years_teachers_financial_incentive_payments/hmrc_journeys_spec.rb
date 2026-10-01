require "rails_helper"

RSpec.feature "EYTFI hmrc journeys", feature_flag: [:eytfi_journey] do
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

  around do |example|
    travel_to(Date.new(2026, 9, 30).beginning_of_day) do
      example.run
    end
  end

  before do
    FeatureFlag.enable!(:eytrp_hmrc_integration)

    create(
      :journey_configuration,
      :early_years_teachers_financial_incentive_payments
    )

    create(:eligible_eytfi_provider, name: "Springfield nursery")

    create(:eligible_eytfi_provider, name: "Other nursery")

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

    stub_request(
      :post,
      "https://test-api.service.hmrc.gov.uk/oauth/token"
    ).with(
      body: {
        "client_id" => /.*/,
        "client_secret" => /.*/,
        "grant_type" => "client_credentials"
      }
    ).to_return(
      status: 200,
      body: {
        access_token: "abc123",
        expires_in: 5.days
      }.to_json
    )

    stub_request(
      :post,
      "https://test-api.service.hmrc.gov.uk/individuals/matching/"
    ).with(
      body: {
        firstName: "John",
        lastName: "Doe",
        nino: "AB123456C",
        dateOfBirth: "1970-12-13"
      },
      headers: {
        "Authorization" => "Bearer abc123"
      }
    ).to_return(
      status: 200,
      body: {
        "_links" => {
          "individual" => {
            "href" => "individuals/matching/12345"
          }
        }
      }.to_json
    )
  end

  context "Response error from HMRC" do
    scenario "User continues on the upload employment evidence journey" do
      stub_request(
        :get,
        "https://test-api.service.hmrc.gov.uk/individuals/employments/paye?fromDate=2026-07-30&matchId=12345"
      ).with(
        headers: {
          "Authorization" => "Bearer abc123"
        }
      ).to_return(
        status: 500,
        body: {code: "INTERNAL_SERVER_ERROR"}.to_json,
        headers: {"Content-Type" => "application/json"}
      )

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
    end
  end

  context "Hmrc not employed at setting" do
    scenario "User needs to upload employment evidence" do
      stub_request(
        :get,
        "https://test-api.service.hmrc.gov.uk/individuals/employments/paye?fromDate=2026-07-30&matchId=12345"
      ).with(
        headers: {
          "Authorization" => "Bearer abc123"
        }
      ).to_return(
        status: 200,
        body: {
          employments: [
            {
              startDate: "2026-01-01",
              endDate: nil,
              payFrequency: "MONTHLY",
              employer: {
                name: "Not an eligibile nursery",
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
        }.to_json,
        headers: {
          "Content-Type" => "application/json"
        }
      )

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

      choose "Yes, add this file"

      click_button "Continue"

      expect(page).to have_text "You may be eligible for a recognition payment"
    end
  end

  context "Hmrc employed at setting" do
    scenario "User doesn't need to upload employment evidence" do
      stub_request(
        :get,
        "https://test-api.service.hmrc.gov.uk/individuals/employments/paye?fromDate=2026-07-30&matchId=12345"
      ).with(
        headers: {
          "Authorization" => "Bearer abc123"
        }
      ).to_return(
        status: 200,
        body: {
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
        }.to_json,
        headers: {
          "Content-Type" => "application/json"
        }
      )

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
    end

    # Complete journey with nursery matching hmrc, change the nursery on the
    # check answers page to one that doesn't match with hmrc upload employment
    # proof. NOTE we don't need to make a new api call to HMRC as we've not
    # changed any details used in the request.
    scenario "User changes setting and now needs to upload employment info" do
      stub_request(
        :get,
        "https://test-api.service.hmrc.gov.uk/individuals/employments/paye?fromDate=2026-07-30&matchId=12345"
      ).with(
        headers: {
          "Authorization" => "Bearer abc123"
        }
      ).to_return(
        status: 200,
        body: {
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
        }.to_json,
        headers: {
          "Content-Type" => "application/json"
        }
      )

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

      # Complete rest of the journey up to check answers
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
      expect(page).not_to have_content("Uploaded payslip")

      click_on "Change nursery"

      expect(page).to have_text "Which nursery do you teach in?"
      find_field("claim[nursery_search_query]").set("Other nursery")
      click_button "Continue"

      expect(page).to have_text "Which nursery do you teach in?"
      choose "Other nursery"
      click_button "Continue"

      expect(page).to have_content(
        "We could not confirm that you work at the nursery you selected"
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

      expect(page).to have_content(
        "Confirm your details and complete your claim"
      )
      expect(page).to have_content("Uploaded payslip")
    end

    # Complete journey with nursery matching HMRC, change national insurance
    # number from check answers page as NINO has changed we make a new api
    # call to hmrc which, in this case, doesn't return employment information
    # so the claimant has to go down the upload employment info route
    scenario "User changes NINO and now needs to upload employment info" do
      stub_request(
        :get,
        "https://test-api.service.hmrc.gov.uk/individuals/employments/paye?fromDate=2026-07-30&matchId=12345"
      ).with(
        headers: {
          "Authorization" => "Bearer abc123"
        }
      ).to_return(
        status: 200,
        body: {
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
        }.to_json,
        headers: {
          "Content-Type" => "application/json"
        }
      )

      stub_request(
        :post,
        "https://test-api.service.hmrc.gov.uk/individuals/matching/"
      ).with(
        body: {
          firstName: "John",
          lastName: "Doe",
          nino: "BB123456C",
          dateOfBirth: "1970-12-13"
        },
        headers: {
          "Authorization" => "Bearer abc123"
        }
      ).to_return(
        status: 200,
        body: {
          "_links" => {
            "individual" => {
              "href" => "individuals/matching/67890"
            }
          }
        }.to_json
      )

      stub_request(
        :get,
        "https://test-api.service.hmrc.gov.uk/individuals/employments/paye?fromDate=2026-07-30&matchId=67890"
      ).with(
        headers: {
          "Authorization" => "Bearer abc123"
        }
      ).to_return(
        status: 200,
        body: {
          employments: []
        }.to_json,
        headers: {
          "Content-Type" => "application/json"
        }
      )

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

      # Complete rest of the journey up to check answers
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
      expect(page).not_to have_content("Uploaded payslip")

      click_on "Change national insurance number"
      expect(page).to have_content "Is this your National Insurance number?"
      choose "No"
      fill_in "What is your National Insurance number?", with: "BB123456C"
      click_on "Continue"

      expect(page).to have_content "Loading"
      perform_enqueued_jobs
      visit current_path # save waiting for the page to reload

      expect(page).to have_content(
        "We could not confirm that you work at the nursery you selected"
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

      # FIXME - currenlty going from check answers -> to upload employment
      # loses the fact that we're changing an answers so we have to
      # re-navigate the journey, fixing this is outside the scope of this PR
      visit claim_path(
        Journeys::EarlyYearsTeachersFinancialIncentivePayments.routing_name,
        "check-your-answers"
      )

      expect(page).to have_text "Confirm your details and complete your claim"
      expect(page).to have_content("Uploaded payslip")
    end

    # Complete the journey with a nursery not matching HMRC, change national
    # insurance number to one that matches
    scenario "User changes NINO and now works at new setting" do
      travel_to Date.new(2026, 9, 30).beginning_of_day

      stub_request(
        :get,
        "https://test-api.service.hmrc.gov.uk/individuals/employments/paye?fromDate=2026-07-30&matchId=12345"
      ).with(
        headers: {
          "Authorization" => "Bearer abc123"
        }
      ).to_return(
        status: 200,
        body: {
          employments: []
        }.to_json,
        headers: {
          "Content-Type" => "application/json"
        }
      )

      stub_request(
        :post,
        "https://test-api.service.hmrc.gov.uk/individuals/matching/"
      ).with(
        body: {
          firstName: "John",
          lastName: "Doe",
          nino: "BB123456C",
          dateOfBirth: "1970-12-13"
        },
        headers: {
          "Authorization" => "Bearer abc123"
        }
      ).to_return(
        status: 200,
        body: {
          "_links" => {
            "individual" => {
              "href" => "individuals/matching/67890"
            }
          }
        }.to_json
      )

      stub_request(
        :get,
        "https://test-api.service.hmrc.gov.uk/individuals/employments/paye?fromDate=2026-07-30&matchId=67890"
      ).with(
        headers: {
          "Authorization" => "Bearer abc123"
        }
      ).to_return(
        status: 200,
        body: {
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
        }.to_json,
        headers: {
          "Content-Type" => "application/json"
        }
      )

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

      expect(page).to have_content(
        "We could not confirm that you work at the nursery you selected"
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
      expect(page).to have_content("Uploaded payslip")

      click_on "Change national insurance number"
      expect(page).to have_content "Is this your National Insurance number?"
      choose "No"
      fill_in "What is your National Insurance number?", with: "BB123456C"
      click_on "Continue"

      expect(page).to have_content "Loading"
      perform_enqueued_jobs
      visit current_path # save waiting for the page to reload

      # FIXME - currently we're dropping the fact that we're changing answer
      # so have to go through the rest of the journey
      visit claim_path(
        Journeys::EarlyYearsTeachersFinancialIncentivePayments.routing_name,
        "check-your-answers"
      )

      expect(page).to have_text "Confirm your details and complete your claim"
      expect(page).to have_content("Uploaded payslip")
      expect(page).to have_content("BB123456C")
    end
  end
end
