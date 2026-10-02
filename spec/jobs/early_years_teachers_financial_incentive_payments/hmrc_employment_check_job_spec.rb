require "rails_helper"

RSpec.describe(
  EarlyYearsTeachersFinancialIncentivePayments::HmrcEmploymentCheckJob
) do
  around do |example|
    travel_to DateTime.new(2026, 9, 30, 0, 0, 0) do
      example.run
    end
  end

  before do
    allow(Hmrc::Employments).to receive(:configuration) do
      double(
        base_url: "https://test-api.service.hmrc.gov.uk",
        client_id: "claim-hmrc-employments-client",
        client_secret: "client-secret",
        totp_secret: "totpsecret",
        enabled: true,
        http_client: Faraday,
        logger: Rails.logger
      )
    end

    FeatureFlag.enable!(:eytrp_hmrc_integration)
  end

  context "when the HMRC API call fails" do
    context "when an error is returned from the HMRC API" do
      it "stores the error response from employment history" do
        nursery = create(:eligible_eytfi_provider, name: "Springfield nursery")

        journey_session = create(
          :eytfi_session,
          answers: {
            nursery_id: nursery.id,
            teacher_auth_verified_name: "John Doe",
            teacher_auth_verified_date_of_birth: "1970-12-13",
            national_insurance_number: "AB123456C"
          }
        )

        stub_request(
          :post,
          "https://test-api.service.hmrc.gov.uk/oauth/token"
        ).with(
          body: {
            "grant_type" => "client_credentials",
            "client_id" => /.*/,
            "client_secret" => /.*/
          }
        ).to_return(
          status: 200,
          body: {
            access_token: "abc123",
            expires_in: 3600
          }.to_json
        )

        matching_request = stub_request(
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
            "Authorization" => "Bearer abc123",
            "Accept" => "application/vnd.hmrc.2.0+json"
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

        response_body = {
          code: "INTERNAL_SERVER_ERROR"
        }.to_json

        employment_request = stub_request(
          :get,
          "https://test-api.service.hmrc.gov.uk/individuals/employments/paye"
        ).with(
          query: {
            fromDate: "2026-08-30",
            matchId: "12345"
          },
          headers: {
            "Authorization" => "Bearer abc123",
            "Accept" => "application/vnd.hmrc.2.0+json"
          }
        ).to_return(
          status: 500,
          body: response_body,
          headers: {
            "Content-Type" => "application/json"
          }
        )

        described_class.perform_now(journey_session)

        answers = journey_session.reload.answers
        expect(answers.hmrc_response_received?).to eq(true)
        expect(answers.hmrc_response_status).to eq(500)
        expect(answers.hmrc_employment_check_passed).to eq(false)
        expect(answers.hmrc_response_body).to eq(response_body)
        expect(matching_request).to have_been_requested.once
        expect(employment_request).to have_been_requested.once
      end

      it "stores the error response from matching" do
        nursery = create(:eligible_eytfi_provider, name: "Springfield nursery")

        journey_session = create(
          :eytfi_session,
          answers: {
            nursery_id: nursery.id,
            teacher_auth_verified_name: "John Doe",
            teacher_auth_verified_date_of_birth: "1970-12-13",
            national_insurance_number: "AB123456C"
          }
        )

        stub_request(
          :post,
          "https://test-api.service.hmrc.gov.uk/oauth/token"
        ).with(
          body: {
            "grant_type" => "client_credentials",
            "client_id" => /.*/,
            "client_secret" => /.*/
          }
        ).to_return(
          status: 200,
          body: {
            access_token: "abc123",
            expires_in: 3600
          }.to_json
        )

        response_body = {
          code: "INTERNAL_SERVER_ERROR"
        }.to_json

        matching_request = stub_request(
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
            "Authorization" => "Bearer abc123",
            "Accept" => "application/vnd.hmrc.2.0+json"
          }
        ).to_return(
          status: 500,
          body: response_body
        )

        described_class.perform_now(journey_session)

        answers = journey_session.reload.answers
        expect(answers.hmrc_response_received?).to eq(true)
        expect(answers.hmrc_response_status).to eq(500)
        expect(answers.hmrc_employment_check_passed).to eq(false)
        expect(answers.hmrc_response_body).to eq(response_body)
        expect(matching_request).to have_been_requested.once
        expect(
          a_request(
            :get,
            "https://test-api.service.hmrc.gov.uk/individuals/employments/paye"
          )
        ).not_to have_been_made
      end
    end

    context "when the claimant is not found on the matching API" do
      it "completes the check without requesting employment history" do
        nursery = create(:eligible_eytfi_provider, name: "Springfield nursery")

        journey_session = create(
          :eytfi_session,
          answers: {
            nursery_id: nursery.id,
            teacher_auth_verified_name: "John Doe",
            teacher_auth_verified_date_of_birth: "1970-12-13",
            national_insurance_number: "AB123456C"
          }
        )

        stub_request(
          :post,
          "https://test-api.service.hmrc.gov.uk/oauth/token"
        ).with(
          body: {
            "grant_type" => "client_credentials",
            "client_id" => /.*/,
            "client_secret" => /.*/
          }
        ).to_return(
          status: 200,
          body: {
            access_token: "abc123",
            expires_in: 3600
          }.to_json
        )

        response_body = {
          code: "MATCHING_FAILED"
        }.to_json

        matching_request = stub_request(
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
            "Authorization" => "Bearer abc123",
            "Accept" => "application/vnd.hmrc.2.0+json"
          }
        ).to_return(
          status: 404,
          body: response_body
        )

        described_class.perform_now(journey_session)

        answers = journey_session.reload.answers
        expect(answers.hmrc_response_received?).to eq(true)
        expect(answers.hmrc_response_status).to eq(404)
        expect(answers.hmrc_employment_check_passed).to eq(false)
        expect(answers.hmrc_response_body).to eq(response_body)
        expect(matching_request).to have_been_requested.once
        expect(
          a_request(
            :get,
            "https://test-api.service.hmrc.gov.uk/individuals/employments/paye"
          )
        ).not_to have_been_made
      end

      it "handles a matching response without an individual link" do
        nursery = create(:eligible_eytfi_provider, name: "Springfield nursery")

        journey_session = create(
          :eytfi_session,
          answers: {
            nursery_id: nursery.id,
            teacher_auth_verified_name: "John Doe",
            teacher_auth_verified_date_of_birth: "1970-12-13",
            national_insurance_number: "AB123456C"
          }
        )

        stub_request(
          :post,
          "https://test-api.service.hmrc.gov.uk/oauth/token"
        ).with(
          body: {
            "grant_type" => "client_credentials",
            "client_id" => /.*/,
            "client_secret" => /.*/
          }
        ).to_return(
          status: 200,
          body: {
            access_token: "abc123",
            expires_in: 3600
          }.to_json
        )

        response_body = {}.to_json

        matching_request = stub_request(
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
            "Authorization" => "Bearer abc123",
            "Accept" => "application/vnd.hmrc.2.0+json"
          }
        ).to_return(
          status: 200,
          body: response_body
        )

        described_class.perform_now(journey_session)

        answers = journey_session.reload.answers
        expect(answers.hmrc_response_received?).to eq(true)
        expect(answers.hmrc_response_status).to eq(200)
        expect(answers.hmrc_employment_check_passed).to eq(false)
        expect(answers.hmrc_response_body).to eq(response_body)
        expect(matching_request).to have_been_requested.once
        expect(
          a_request(
            :get,
            "https://test-api.service.hmrc.gov.uk/individuals/employments/paye"
          )
        ).not_to have_been_made
      end
    end

    context "when the response from HMRC is not the right shape" do
      it "handles invalid JSON" do
        nursery = create(:eligible_eytfi_provider, name: "Springfield nursery")

        journey_session = create(
          :eytfi_session,
          answers: {
            nursery_id: nursery.id,
            teacher_auth_verified_name: "John Doe",
            teacher_auth_verified_date_of_birth: "1970-12-13",
            national_insurance_number: "AB123456C"
          }
        )

        stub_request(
          :post,
          "https://test-api.service.hmrc.gov.uk/oauth/token"
        ).with(
          body: {
            "grant_type" => "client_credentials",
            "client_id" => /.*/,
            "client_secret" => /.*/
          }
        ).to_return(
          status: 200,
          body: {
            access_token: "abc123",
            expires_in: 3600
          }.to_json
        )

        matching_request = stub_request(
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
            "Authorization" => "Bearer abc123",
            "Accept" => "application/vnd.hmrc.2.0+json"
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

        response_body = "not JSON"

        employment_request = stub_request(
          :get,
          "https://test-api.service.hmrc.gov.uk/individuals/employments/paye"
        ).with(
          query: {
            fromDate: "2026-08-30",
            matchId: "12345"
          },
          headers: {
            "Authorization" => "Bearer abc123",
            "Accept" => "application/vnd.hmrc.2.0+json"
          }
        ).to_return(
          status: 200,
          body: response_body,
          headers: {
            "Content-Type" => "application/json"
          }
        )

        described_class.perform_now(journey_session)

        answers = journey_session.reload.answers
        expect(answers.hmrc_response_received?).to eq(true)
        expect(answers.hmrc_response_status).to eq(200)
        expect(answers.hmrc_employment_check_passed).to eq(false)
        expect(answers.hmrc_response_body).to eq(response_body)
        expect(matching_request).to have_been_requested.once
        expect(employment_request).to have_been_requested.once
      end

      it "handles a missing employments key" do
        nursery = create(:eligible_eytfi_provider, name: "Springfield nursery")

        journey_session = create(
          :eytfi_session,
          answers: {
            nursery_id: nursery.id,
            teacher_auth_verified_name: "John Doe",
            teacher_auth_verified_date_of_birth: "1970-12-13",
            national_insurance_number: "AB123456C"
          }
        )

        stub_request(
          :post,
          "https://test-api.service.hmrc.gov.uk/oauth/token"
        ).with(
          body: {
            "grant_type" => "client_credentials",
            "client_id" => /.*/,
            "client_secret" => /.*/
          }
        ).to_return(
          status: 200,
          body: {
            access_token: "abc123",
            expires_in: 3600
          }.to_json
        )

        matching_request = stub_request(
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
            "Authorization" => "Bearer abc123",
            "Accept" => "application/vnd.hmrc.2.0+json"
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

        response_body = {}.to_json

        employment_request = stub_request(
          :get,
          "https://test-api.service.hmrc.gov.uk/individuals/employments/paye"
        ).with(
          query: {
            fromDate: "2026-08-30",
            matchId: "12345"
          },
          headers: {
            "Authorization" => "Bearer abc123",
            "Accept" => "application/vnd.hmrc.2.0+json"
          }
        ).to_return(
          status: 200,
          body: response_body,
          headers: {
            "Content-Type" => "application/json"
          }
        )

        described_class.perform_now(journey_session)

        answers = journey_session.reload.answers
        expect(answers.hmrc_response_received?).to eq(true)
        expect(answers.hmrc_response_status).to eq(200)
        expect(answers.hmrc_employment_check_passed).to eq(false)
        expect(answers.hmrc_response_body).to eq(response_body)
        expect(matching_request).to have_been_requested.once
        expect(employment_request).to have_been_requested.once
      end

      it "handles a non-object response" do
        nursery = create(:eligible_eytfi_provider, name: "Springfield nursery")

        journey_session = create(
          :eytfi_session,
          answers: {
            nursery_id: nursery.id,
            teacher_auth_verified_name: "John Doe",
            teacher_auth_verified_date_of_birth: "1970-12-13",
            national_insurance_number: "AB123456C"
          }
        )

        stub_request(
          :post,
          "https://test-api.service.hmrc.gov.uk/oauth/token"
        ).with(
          body: {
            "grant_type" => "client_credentials",
            "client_id" => /.*/,
            "client_secret" => /.*/
          }
        ).to_return(
          status: 200,
          body: {
            access_token: "abc123",
            expires_in: 3600
          }.to_json
        )

        matching_request = stub_request(
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
            "Authorization" => "Bearer abc123",
            "Accept" => "application/vnd.hmrc.2.0+json"
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

        response_body = [].to_json

        employment_request = stub_request(
          :get,
          "https://test-api.service.hmrc.gov.uk/individuals/employments/paye"
        ).with(
          query: {
            fromDate: "2026-08-30",
            matchId: "12345"
          },
          headers: {
            "Authorization" => "Bearer abc123",
            "Accept" => "application/vnd.hmrc.2.0+json"
          }
        ).to_return(
          status: 200,
          body: response_body,
          headers: {
            "Content-Type" => "application/json"
          }
        )

        described_class.perform_now(journey_session)

        answers = journey_session.reload.answers
        expect(answers.hmrc_response_received?).to eq(true)
        expect(answers.hmrc_response_status).to eq(200)
        expect(answers.hmrc_employment_check_passed).to eq(false)
        expect(answers.hmrc_response_body).to eq(response_body)
        expect(matching_request).to have_been_requested.once
        expect(employment_request).to have_been_requested.once
      end

      it "handles a null employment list" do
        nursery = create(:eligible_eytfi_provider, name: "Springfield nursery")

        journey_session = create(
          :eytfi_session,
          answers: {
            nursery_id: nursery.id,
            teacher_auth_verified_name: "John Doe",
            teacher_auth_verified_date_of_birth: "1970-12-13",
            national_insurance_number: "AB123456C"
          }
        )

        stub_request(
          :post,
          "https://test-api.service.hmrc.gov.uk/oauth/token"
        ).with(
          body: {
            "grant_type" => "client_credentials",
            "client_id" => /.*/,
            "client_secret" => /.*/
          }
        ).to_return(
          status: 200,
          body: {
            access_token: "abc123",
            expires_in: 3600
          }.to_json
        )

        matching_request = stub_request(
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
            "Authorization" => "Bearer abc123",
            "Accept" => "application/vnd.hmrc.2.0+json"
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

        response_body = {
          employments: nil
        }.to_json

        employment_request = stub_request(
          :get,
          "https://test-api.service.hmrc.gov.uk/individuals/employments/paye"
        ).with(
          query: {
            fromDate: "2026-08-30",
            matchId: "12345"
          },
          headers: {
            "Authorization" => "Bearer abc123",
            "Accept" => "application/vnd.hmrc.2.0+json"
          }
        ).to_return(
          status: 200,
          body: response_body,
          headers: {
            "Content-Type" => "application/json"
          }
        )

        described_class.perform_now(journey_session)

        answers = journey_session.reload.answers
        expect(answers.hmrc_response_received?).to eq(true)
        expect(answers.hmrc_response_status).to eq(200)
        expect(answers.hmrc_employment_check_passed).to eq(false)
        expect(answers.hmrc_response_body).to eq(response_body)
        expect(matching_request).to have_been_requested.once
        expect(employment_request).to have_been_requested.once
      end

      it "handles an object instead of an employment list" do
        nursery = create(:eligible_eytfi_provider, name: "Springfield nursery")

        journey_session = create(
          :eytfi_session,
          answers: {
            nursery_id: nursery.id,
            teacher_auth_verified_name: "John Doe",
            teacher_auth_verified_date_of_birth: "1970-12-13",
            national_insurance_number: "AB123456C"
          }
        )

        stub_request(
          :post,
          "https://test-api.service.hmrc.gov.uk/oauth/token"
        ).with(
          body: {
            "grant_type" => "client_credentials",
            "client_id" => /.*/,
            "client_secret" => /.*/
          }
        ).to_return(
          status: 200,
          body: {
            access_token: "abc123",
            expires_in: 3600
          }.to_json
        )

        matching_request = stub_request(
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
            "Authorization" => "Bearer abc123",
            "Accept" => "application/vnd.hmrc.2.0+json"
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

        response_body = {
          employments: {}
        }.to_json

        employment_request = stub_request(
          :get,
          "https://test-api.service.hmrc.gov.uk/individuals/employments/paye"
        ).with(
          query: {
            fromDate: "2026-08-30",
            matchId: "12345"
          },
          headers: {
            "Authorization" => "Bearer abc123",
            "Accept" => "application/vnd.hmrc.2.0+json"
          }
        ).to_return(
          status: 200,
          body: response_body,
          headers: {
            "Content-Type" => "application/json"
          }
        )

        described_class.perform_now(journey_session)

        answers = journey_session.reload.answers
        expect(answers.hmrc_response_received?).to eq(true)
        expect(answers.hmrc_response_status).to eq(200)
        expect(answers.hmrc_employment_check_passed).to eq(false)
        expect(answers.hmrc_response_body).to eq(response_body)
        expect(matching_request).to have_been_requested.once
        expect(employment_request).to have_been_requested.once
      end

      it "handles a non-object employment" do
        nursery = create(:eligible_eytfi_provider, name: "Springfield nursery")

        journey_session = create(
          :eytfi_session,
          answers: {
            nursery_id: nursery.id,
            teacher_auth_verified_name: "John Doe",
            teacher_auth_verified_date_of_birth: "1970-12-13",
            national_insurance_number: "AB123456C"
          }
        )

        stub_request(
          :post,
          "https://test-api.service.hmrc.gov.uk/oauth/token"
        ).with(
          body: {
            "grant_type" => "client_credentials",
            "client_id" => /.*/,
            "client_secret" => /.*/
          }
        ).to_return(
          status: 200,
          body: {
            access_token: "abc123",
            expires_in: 3600
          }.to_json
        )

        matching_request = stub_request(
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
            "Authorization" => "Bearer abc123",
            "Accept" => "application/vnd.hmrc.2.0+json"
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

        response_body = {
          employments: [
            nil
          ]
        }.to_json

        employment_request = stub_request(
          :get,
          "https://test-api.service.hmrc.gov.uk/individuals/employments/paye"
        ).with(
          query: {
            fromDate: "2026-08-30",
            matchId: "12345"
          },
          headers: {
            "Authorization" => "Bearer abc123",
            "Accept" => "application/vnd.hmrc.2.0+json"
          }
        ).to_return(
          status: 200,
          body: response_body,
          headers: {
            "Content-Type" => "application/json"
          }
        )

        described_class.perform_now(journey_session)

        answers = journey_session.reload.answers
        expect(answers.hmrc_response_received?).to eq(true)
        expect(answers.hmrc_response_status).to eq(200)
        expect(answers.hmrc_employment_check_passed).to eq(false)
        expect(answers.hmrc_response_body).to eq(response_body)
        expect(matching_request).to have_been_requested.once
        expect(employment_request).to have_been_requested.once
      end

      it "handles a non-object employer" do
        nursery = create(:eligible_eytfi_provider, name: "Springfield nursery")

        journey_session = create(
          :eytfi_session,
          answers: {
            nursery_id: nursery.id,
            teacher_auth_verified_name: "John Doe",
            teacher_auth_verified_date_of_birth: "1970-12-13",
            national_insurance_number: "AB123456C"
          }
        )

        stub_request(
          :post,
          "https://test-api.service.hmrc.gov.uk/oauth/token"
        ).with(
          body: {
            "grant_type" => "client_credentials",
            "client_id" => /.*/,
            "client_secret" => /.*/
          }
        ).to_return(
          status: 200,
          body: {
            access_token: "abc123",
            expires_in: 3600
          }.to_json
        )

        matching_request = stub_request(
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
            "Authorization" => "Bearer abc123",
            "Accept" => "application/vnd.hmrc.2.0+json"
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

        response_body = {
          employments: [
            {
              employer: "invalid"
            }
          ]
        }.to_json

        employment_request = stub_request(
          :get,
          "https://test-api.service.hmrc.gov.uk/individuals/employments/paye"
        ).with(
          query: {
            fromDate: "2026-08-30",
            matchId: "12345"
          },
          headers: {
            "Authorization" => "Bearer abc123",
            "Accept" => "application/vnd.hmrc.2.0+json"
          }
        ).to_return(
          status: 200,
          body: response_body,
          headers: {
            "Content-Type" => "application/json"
          }
        )

        described_class.perform_now(journey_session)

        answers = journey_session.reload.answers
        expect(answers.hmrc_response_received?).to eq(true)
        expect(answers.hmrc_response_status).to eq(200)
        expect(answers.hmrc_employment_check_passed).to eq(false)
        expect(answers.hmrc_response_body).to eq(response_body)
        expect(matching_request).to have_been_requested.once
        expect(employment_request).to have_been_requested.once
      end

      it "handles a non-string employer name" do
        nursery = create(:eligible_eytfi_provider, name: "Springfield nursery")

        journey_session = create(
          :eytfi_session,
          answers: {
            nursery_id: nursery.id,
            teacher_auth_verified_name: "John Doe",
            teacher_auth_verified_date_of_birth: "1970-12-13",
            national_insurance_number: "AB123456C"
          }
        )

        stub_request(
          :post,
          "https://test-api.service.hmrc.gov.uk/oauth/token"
        ).with(
          body: {
            "grant_type" => "client_credentials",
            "client_id" => /.*/,
            "client_secret" => /.*/
          }
        ).to_return(
          status: 200,
          body: {
            access_token: "abc123",
            expires_in: 3600
          }.to_json
        )

        matching_request = stub_request(
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
            "Authorization" => "Bearer abc123",
            "Accept" => "application/vnd.hmrc.2.0+json"
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

        response_body = {
          employments: [
            {
              employer: {
                name: 123
              }
            }
          ]
        }.to_json

        employment_request = stub_request(
          :get,
          "https://test-api.service.hmrc.gov.uk/individuals/employments/paye"
        ).with(
          query: {
            fromDate: "2026-08-30",
            matchId: "12345"
          },
          headers: {
            "Authorization" => "Bearer abc123",
            "Accept" => "application/vnd.hmrc.2.0+json"
          }
        ).to_return(
          status: 200,
          body: response_body,
          headers: {
            "Content-Type" => "application/json"
          }
        )

        described_class.perform_now(journey_session)

        answers = journey_session.reload.answers
        expect(answers.hmrc_response_received?).to eq(true)
        expect(answers.hmrc_response_status).to eq(200)
        expect(answers.hmrc_employment_check_passed).to eq(false)
        expect(answers.hmrc_response_body).to eq(response_body)
        expect(matching_request).to have_been_requested.once
        expect(employment_request).to have_been_requested.once
      end

      it "handles missing employer information" do
        nursery = create(:eligible_eytfi_provider, name: "Springfield nursery")

        journey_session = create(
          :eytfi_session,
          answers: {
            nursery_id: nursery.id,
            teacher_auth_verified_name: "John Doe",
            teacher_auth_verified_date_of_birth: "1970-12-13",
            national_insurance_number: "AB123456C"
          }
        )

        stub_request(
          :post,
          "https://test-api.service.hmrc.gov.uk/oauth/token"
        ).with(
          body: {
            "grant_type" => "client_credentials",
            "client_id" => /.*/,
            "client_secret" => /.*/
          }
        ).to_return(
          status: 200,
          body: {
            access_token: "abc123",
            expires_in: 3600
          }.to_json
        )

        matching_request = stub_request(
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
            "Authorization" => "Bearer abc123",
            "Accept" => "application/vnd.hmrc.2.0+json"
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

        response_body = {
          employments: [
            {
              startDate: "2026-01-01"
            }
          ]
        }.to_json

        employment_request = stub_request(
          :get,
          "https://test-api.service.hmrc.gov.uk/individuals/employments/paye"
        ).with(
          query: {
            fromDate: "2026-08-30",
            matchId: "12345"
          },
          headers: {
            "Authorization" => "Bearer abc123",
            "Accept" => "application/vnd.hmrc.2.0+json"
          }
        ).to_return(
          status: 200,
          body: response_body,
          headers: {
            "Content-Type" => "application/json"
          }
        )

        described_class.perform_now(journey_session)

        answers = journey_session.reload.answers
        expect(answers.hmrc_response_received?).to eq(true)
        expect(answers.hmrc_response_status).to eq(200)
        expect(answers.hmrc_employment_check_passed).to eq(false)
        expect(answers.hmrc_response_body).to eq(response_body)
        expect(matching_request).to have_been_requested.once
        expect(employment_request).to have_been_requested.once
      end

      it "handles a missing employer name" do
        nursery = create(:eligible_eytfi_provider, name: "Springfield nursery")

        journey_session = create(
          :eytfi_session,
          answers: {
            nursery_id: nursery.id,
            teacher_auth_verified_name: "John Doe",
            teacher_auth_verified_date_of_birth: "1970-12-13",
            national_insurance_number: "AB123456C"
          }
        )

        stub_request(
          :post,
          "https://test-api.service.hmrc.gov.uk/oauth/token"
        ).with(
          body: {
            "grant_type" => "client_credentials",
            "client_id" => /.*/,
            "client_secret" => /.*/
          }
        ).to_return(
          status: 200,
          body: {
            access_token: "abc123",
            expires_in: 3600
          }.to_json
        )

        matching_request = stub_request(
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
            "Authorization" => "Bearer abc123",
            "Accept" => "application/vnd.hmrc.2.0+json"
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

        response_body = {
          employments: [
            {
              employer: {}
            }
          ]
        }.to_json

        employment_request = stub_request(
          :get,
          "https://test-api.service.hmrc.gov.uk/individuals/employments/paye"
        ).with(
          query: {
            fromDate: "2026-08-30",
            matchId: "12345"
          },
          headers: {
            "Authorization" => "Bearer abc123",
            "Accept" => "application/vnd.hmrc.2.0+json"
          }
        ).to_return(
          status: 200,
          body: response_body,
          headers: {
            "Content-Type" => "application/json"
          }
        )

        described_class.perform_now(journey_session)

        answers = journey_session.reload.answers
        expect(answers.hmrc_response_received?).to eq(true)
        expect(answers.hmrc_response_status).to eq(200)
        expect(answers.hmrc_employment_check_passed).to eq(false)
        expect(answers.hmrc_response_body).to eq(response_body)
        expect(matching_request).to have_been_requested.once
        expect(employment_request).to have_been_requested.once
      end
    end
  end

  context "when the HMRC API call succeeds" do
    context "when the claimant is employed at the setting" do
      it "passes the check when employment dates are absent" do
        nursery = create(:eligible_eytfi_provider, name: "Springfield nursery")

        journey_session = create(
          :eytfi_session,
          answers: {
            nursery_id: nursery.id,
            teacher_auth_verified_name: "John Doe",
            teacher_auth_verified_date_of_birth: "1970-12-13",
            national_insurance_number: "AB123456C"
          }
        )

        stub_request(
          :post,
          "https://test-api.service.hmrc.gov.uk/oauth/token"
        ).with(
          body: {
            "grant_type" => "client_credentials",
            "client_id" => /.*/,
            "client_secret" => /.*/
          }
        ).to_return(
          status: 200,
          body: {
            access_token: "abc123",
            expires_in: 3600
          }.to_json
        )

        employments = [
          {
            employer: {
              name: "Springfield nursery"
            }
          }
        ]

        matching_request = stub_request(
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
            "Authorization" => "Bearer abc123",
            "Accept" => "application/vnd.hmrc.2.0+json"
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

        response_body = {
          employments: employments
        }.to_json

        employment_request = stub_request(
          :get,
          "https://test-api.service.hmrc.gov.uk/individuals/employments/paye"
        ).with(
          query: {
            fromDate: "2026-08-30",
            matchId: "12345"
          },
          headers: {
            "Authorization" => "Bearer abc123",
            "Accept" => "application/vnd.hmrc.2.0+json"
          }
        ).to_return(
          status: 200,
          body: response_body,
          headers: {
            "Content-Type" => "application/json"
          }
        )

        described_class.perform_now(journey_session)

        answers = journey_session.reload.answers
        expect(answers.hmrc_response_received?).to eq(true)
        expect(answers.hmrc_response_status).to eq(200)
        expect(answers.hmrc_employment_check_passed).to eq(true)
        expect(answers.hmrc_response_body).to eq(response_body)
        expect(matching_request).to have_been_requested.once
        expect(employment_request).to have_been_requested.once
      end

      it "passes the check regardless of employment dates" do
        nursery = create(:eligible_eytfi_provider, name: "Springfield nursery")

        journey_session = create(
          :eytfi_session,
          answers: {
            nursery_id: nursery.id,
            teacher_auth_verified_name: "John Doe",
            teacher_auth_verified_date_of_birth: "1970-12-13",
            national_insurance_number: "AB123456C"
          }
        )

        stub_request(
          :post,
          "https://test-api.service.hmrc.gov.uk/oauth/token"
        ).with(
          body: {
            "grant_type" => "client_credentials",
            "client_id" => /.*/,
            "client_secret" => /.*/
          }
        ).to_return(
          status: 200,
          body: {
            access_token: "abc123",
            expires_in: 3600
          }.to_json
        )

        employments = [
          {
            startDate: "2026-01-01",
            endDate: "2026-09-01",
            employer: {
              name: "Springfield nursery"
            }
          }
        ]

        matching_request = stub_request(
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
            "Authorization" => "Bearer abc123",
            "Accept" => "application/vnd.hmrc.2.0+json"
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

        response_body = {
          employments: employments
        }.to_json

        employment_request = stub_request(
          :get,
          "https://test-api.service.hmrc.gov.uk/individuals/employments/paye"
        ).with(
          query: {
            fromDate: "2026-08-30",
            matchId: "12345"
          },
          headers: {
            "Authorization" => "Bearer abc123",
            "Accept" => "application/vnd.hmrc.2.0+json"
          }
        ).to_return(
          status: 200,
          body: response_body,
          headers: {
            "Content-Type" => "application/json"
          }
        )

        described_class.perform_now(journey_session)

        answers = journey_session.reload.answers
        expect(answers.hmrc_response_received?).to eq(true)
        expect(answers.hmrc_response_status).to eq(200)
        expect(answers.hmrc_employment_check_passed).to eq(true)
        expect(answers.hmrc_response_body).to eq(response_body)
        expect(matching_request).to have_been_requested.once
        expect(employment_request).to have_been_requested.once
      end
    end

    context "when the claimant is not employed at the setting" do
      it "persists employment at another setting without passing the check" do
        nursery = create(:eligible_eytfi_provider, name: "Springfield nursery")

        journey_session = create(
          :eytfi_session,
          answers: {
            nursery_id: nursery.id,
            teacher_auth_verified_name: "John Doe",
            teacher_auth_verified_date_of_birth: "1970-12-13",
            national_insurance_number: "AB123456C"
          }
        )

        stub_request(
          :post,
          "https://test-api.service.hmrc.gov.uk/oauth/token"
        ).with(
          body: {
            "grant_type" => "client_credentials",
            "client_id" => /.*/,
            "client_secret" => /.*/
          }
        ).to_return(
          status: 200,
          body: {
            access_token: "abc123",
            expires_in: 3600
          }.to_json
        )

        employments = [
          {
            employer: {
              name: "Other nursery"
            }
          }
        ]

        matching_request = stub_request(
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
            "Authorization" => "Bearer abc123",
            "Accept" => "application/vnd.hmrc.2.0+json"
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

        response_body = {
          employments: employments
        }.to_json

        employment_request = stub_request(
          :get,
          "https://test-api.service.hmrc.gov.uk/individuals/employments/paye"
        ).with(
          query: {
            fromDate: "2026-08-30",
            matchId: "12345"
          },
          headers: {
            "Authorization" => "Bearer abc123",
            "Accept" => "application/vnd.hmrc.2.0+json"
          }
        ).to_return(
          status: 200,
          body: response_body,
          headers: {
            "Content-Type" => "application/json"
          }
        )

        described_class.perform_now(journey_session)

        answers = journey_session.reload.answers
        expect(answers.hmrc_response_received?).to eq(true)
        expect(answers.hmrc_response_status).to eq(200)
        expect(answers.hmrc_employment_check_passed).to eq(false)
        expect(answers.hmrc_response_body).to eq(response_body)
        expect(matching_request).to have_been_requested.once
        expect(employment_request).to have_been_requested.once
      end

      it "persists an empty history without passing the check" do
        nursery = create(:eligible_eytfi_provider, name: "Springfield nursery")

        journey_session = create(
          :eytfi_session,
          answers: {
            nursery_id: nursery.id,
            teacher_auth_verified_name: "John Doe",
            teacher_auth_verified_date_of_birth: "1970-12-13",
            national_insurance_number: "AB123456C"
          }
        )

        stub_request(
          :post,
          "https://test-api.service.hmrc.gov.uk/oauth/token"
        ).with(
          body: {
            "grant_type" => "client_credentials",
            "client_id" => /.*/,
            "client_secret" => /.*/
          }
        ).to_return(
          status: 200,
          body: {
            access_token: "abc123",
            expires_in: 3600
          }.to_json
        )

        employments = []

        matching_request = stub_request(
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
            "Authorization" => "Bearer abc123",
            "Accept" => "application/vnd.hmrc.2.0+json"
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

        response_body = {
          employments: employments
        }.to_json

        employment_request = stub_request(
          :get,
          "https://test-api.service.hmrc.gov.uk/individuals/employments/paye"
        ).with(
          query: {
            fromDate: "2026-08-30",
            matchId: "12345"
          },
          headers: {
            "Authorization" => "Bearer abc123",
            "Accept" => "application/vnd.hmrc.2.0+json"
          }
        ).to_return(
          status: 200,
          body: response_body,
          headers: {
            "Content-Type" => "application/json"
          }
        )

        described_class.perform_now(journey_session)

        answers = journey_session.reload.answers
        expect(answers.hmrc_response_received?).to eq(true)
        expect(answers.hmrc_response_status).to eq(200)
        expect(answers.hmrc_employment_check_passed).to eq(false)
        expect(answers.hmrc_response_body).to eq(response_body)
        expect(matching_request).to have_been_requested.once
        expect(employment_request).to have_been_requested.once
      end
    end
  end

  context "when the job has already completed" do
    it "preserves the stored result without making HTTP requests" do
      journey_session = create(
        :eytfi_session,
        answers: {
          hmrc_response_status: 200,
          hmrc_response_body: {employments: []}.to_json
        }
      )
      original_answers = journey_session.answers.attributes

      described_class.perform_now(journey_session)

      expect(journey_session.reload.answers.attributes).to eq(original_answers)
      expect(a_request(:any, /service\.hmrc\.gov\.uk/)).not_to have_been_made
    end

    it "skips HTTP requests when only a status is stored" do
      journey_session = create(
        :eytfi_session,
        answers: {
          hmrc_response_status: 404
        }
      )
      original_answers = journey_session.answers.attributes

      described_class.perform_now(journey_session)

      expect(journey_session.reload.answers.attributes).to eq(original_answers)
      expect(a_request(:any, /service\.hmrc\.gov\.uk/)).not_to have_been_made
    end

    it "skips HTTP requests when only a body is stored" do
      journey_session = create(
        :eytfi_session,
        answers: {
          hmrc_response_body: {employments: []}.to_json
        }
      )
      original_answers = journey_session.answers.attributes

      described_class.perform_now(journey_session)

      expect(journey_session.reload.answers.attributes).to eq(original_answers)
      expect(a_request(:any, /service\.hmrc\.gov\.uk/)).not_to have_been_made
    end
  end
end
