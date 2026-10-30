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
    FeatureFlag.enable!(:eytrp_hmrc_integration)

    allow_any_instance_of(
      Hmrc::Employments::Configuration
    ).to receive(:base_url) { "https://test-api.service.hmrc.gov.uk" }

    allow_any_instance_of(
      Hmrc::Employments::Configuration
    ).to receive(:client_id) { "claim-hmrc-employments-client" }

    allow_any_instance_of(
      Hmrc::Employments::Configuration
    ).to receive(:client_secret) { "client-secret" }

    allow_any_instance_of(
      Hmrc::Employments::Configuration
    ).to receive(:totp_secret) { "totpsecret" }
  end

  context "when the HMRC API call fails" do
    context "when an error is returned from the HMRC API" do
      it "fetches and stores a response when a body exists without a status" do
        nursery = create(:eligible_eytfi_provider, name: "Springfield nursery")

        claim = create(
          :claim,
          policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
          first_name: "Claimant",
          surname: "Entered",
          date_of_birth: "1980-01-01",
          national_insurance_number: "AB123456C",
          eligibility_attributes: {
            eligible_eytfi_provider_urn: nursery.urn,
            teacher_auth_verified_name: "John Middle Doe",
            teacher_auth_verified_date_of_birth: "1970-12-13",
            hmrc_response_body: "previous incomplete response"
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
            fromDate: "2026-07-30",
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

        described_class.perform_now(claim)

        eligibility = claim.eligibility.reload
        expect(eligibility.hmrc_response_status).to eq(500)
        expect(eligibility.hmrc_response_body).to eq(response_body)
        expect(matching_request).to have_been_requested.once
        expect(employment_request).to have_been_requested.once
      end

      it "stores the error response from matching" do
        nursery = create(:eligible_eytfi_provider, name: "Springfield nursery")

        claim = create(
          :claim,
          policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
          first_name: "Claimant",
          surname: "Entered",
          date_of_birth: "1980-01-01",
          national_insurance_number: "AB123456C",
          eligibility_attributes: {
            eligible_eytfi_provider_urn: nursery.urn,
            teacher_auth_verified_name: "John Middle Doe",
            teacher_auth_verified_date_of_birth: "1970-12-13"
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

        described_class.perform_now(claim)

        eligibility = claim.eligibility.reload
        expect(eligibility.hmrc_response_status).to eq(500)
        expect(eligibility.hmrc_response_body).to eq(response_body)
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

        claim = create(
          :claim,
          policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
          first_name: "Claimant",
          surname: "Entered",
          date_of_birth: "1980-01-01",
          national_insurance_number: "AB123456C",
          eligibility_attributes: {
            eligible_eytfi_provider_urn: nursery.urn,
            teacher_auth_verified_name: "John Middle Doe",
            teacher_auth_verified_date_of_birth: "1970-12-13"
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

        described_class.perform_now(claim)

        eligibility = claim.eligibility.reload
        expect(eligibility.hmrc_response_status).to eq(404)
        expect(eligibility.hmrc_response_body).to eq(response_body)
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

        claim = create(
          :claim,
          policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
          first_name: "Claimant",
          surname: "Entered",
          date_of_birth: "1980-01-01",
          national_insurance_number: "AB123456C",
          eligibility_attributes: {
            eligible_eytfi_provider_urn: nursery.urn,
            teacher_auth_verified_name: "John Middle Doe",
            teacher_auth_verified_date_of_birth: "1970-12-13"
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

        described_class.perform_now(claim)

        eligibility = claim.eligibility.reload
        expect(eligibility.hmrc_response_status).to eq(200)
        expect(eligibility.hmrc_response_body).to eq(response_body)
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

        claim = create(
          :claim,
          policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
          first_name: "Claimant",
          surname: "Entered",
          date_of_birth: "1980-01-01",
          national_insurance_number: "AB123456C",
          eligibility_attributes: {
            eligible_eytfi_provider_urn: nursery.urn,
            teacher_auth_verified_name: "John Middle Doe",
            teacher_auth_verified_date_of_birth: "1970-12-13"
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
            fromDate: "2026-07-30",
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

        described_class.perform_now(claim)

        eligibility = claim.eligibility.reload
        expect(eligibility.hmrc_response_status).to eq(200)
        expect(eligibility.hmrc_response_body).to eq(response_body)
        expect(matching_request).to have_been_requested.once
        expect(employment_request).to have_been_requested.once
      end

      it "handles a missing employments key" do
        nursery = create(:eligible_eytfi_provider, name: "Springfield nursery")

        claim = create(
          :claim,
          policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
          first_name: "Claimant",
          surname: "Entered",
          date_of_birth: "1980-01-01",
          national_insurance_number: "AB123456C",
          eligibility_attributes: {
            eligible_eytfi_provider_urn: nursery.urn,
            teacher_auth_verified_name: "John Middle Doe",
            teacher_auth_verified_date_of_birth: "1970-12-13"
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
            fromDate: "2026-07-30",
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

        described_class.perform_now(claim)

        eligibility = claim.eligibility.reload
        expect(eligibility.hmrc_response_status).to eq(200)
        expect(eligibility.hmrc_response_body).to eq(response_body)
        expect(matching_request).to have_been_requested.once
        expect(employment_request).to have_been_requested.once
      end

      it "handles a non-object response" do
        nursery = create(:eligible_eytfi_provider, name: "Springfield nursery")

        claim = create(
          :claim,
          policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
          first_name: "Claimant",
          surname: "Entered",
          date_of_birth: "1980-01-01",
          national_insurance_number: "AB123456C",
          eligibility_attributes: {
            eligible_eytfi_provider_urn: nursery.urn,
            teacher_auth_verified_name: "John Middle Doe",
            teacher_auth_verified_date_of_birth: "1970-12-13"
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
            fromDate: "2026-07-30",
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

        described_class.perform_now(claim)

        eligibility = claim.eligibility.reload
        expect(eligibility.hmrc_response_status).to eq(200)
        expect(eligibility.hmrc_response_body).to eq(response_body)
        expect(matching_request).to have_been_requested.once
        expect(employment_request).to have_been_requested.once
      end

      it "handles a null employment list" do
        nursery = create(:eligible_eytfi_provider, name: "Springfield nursery")

        claim = create(
          :claim,
          policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
          first_name: "Claimant",
          surname: "Entered",
          date_of_birth: "1980-01-01",
          national_insurance_number: "AB123456C",
          eligibility_attributes: {
            eligible_eytfi_provider_urn: nursery.urn,
            teacher_auth_verified_name: "John Middle Doe",
            teacher_auth_verified_date_of_birth: "1970-12-13"
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
            fromDate: "2026-07-30",
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

        described_class.perform_now(claim)

        eligibility = claim.eligibility.reload
        expect(eligibility.hmrc_response_status).to eq(200)
        expect(eligibility.hmrc_response_body).to eq(response_body)
        expect(matching_request).to have_been_requested.once
        expect(employment_request).to have_been_requested.once
      end

      it "handles an object instead of an employment list" do
        nursery = create(:eligible_eytfi_provider, name: "Springfield nursery")

        claim = create(
          :claim,
          policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
          first_name: "Claimant",
          surname: "Entered",
          date_of_birth: "1980-01-01",
          national_insurance_number: "AB123456C",
          eligibility_attributes: {
            eligible_eytfi_provider_urn: nursery.urn,
            teacher_auth_verified_name: "John Middle Doe",
            teacher_auth_verified_date_of_birth: "1970-12-13"
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
            fromDate: "2026-07-30",
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

        described_class.perform_now(claim)

        eligibility = claim.eligibility.reload
        expect(eligibility.hmrc_response_status).to eq(200)
        expect(eligibility.hmrc_response_body).to eq(response_body)
        expect(matching_request).to have_been_requested.once
        expect(employment_request).to have_been_requested.once
      end

      it "handles a non-object employment" do
        nursery = create(:eligible_eytfi_provider, name: "Springfield nursery")

        claim = create(
          :claim,
          policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
          first_name: "Claimant",
          surname: "Entered",
          date_of_birth: "1980-01-01",
          national_insurance_number: "AB123456C",
          eligibility_attributes: {
            eligible_eytfi_provider_urn: nursery.urn,
            teacher_auth_verified_name: "John Middle Doe",
            teacher_auth_verified_date_of_birth: "1970-12-13"
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
            fromDate: "2026-07-30",
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

        described_class.perform_now(claim)

        eligibility = claim.eligibility.reload
        expect(eligibility.hmrc_response_status).to eq(200)
        expect(eligibility.hmrc_response_body).to eq(response_body)
        expect(matching_request).to have_been_requested.once
        expect(employment_request).to have_been_requested.once
      end

      it "handles a non-object employer" do
        nursery = create(:eligible_eytfi_provider, name: "Springfield nursery")

        claim = create(
          :claim,
          policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
          first_name: "Claimant",
          surname: "Entered",
          date_of_birth: "1980-01-01",
          national_insurance_number: "AB123456C",
          eligibility_attributes: {
            eligible_eytfi_provider_urn: nursery.urn,
            teacher_auth_verified_name: "John Middle Doe",
            teacher_auth_verified_date_of_birth: "1970-12-13"
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
            fromDate: "2026-07-30",
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

        described_class.perform_now(claim)

        eligibility = claim.eligibility.reload
        expect(eligibility.hmrc_response_status).to eq(200)
        expect(eligibility.hmrc_response_body).to eq(response_body)
        expect(matching_request).to have_been_requested.once
        expect(employment_request).to have_been_requested.once
      end

      it "handles a non-string employer name" do
        nursery = create(:eligible_eytfi_provider, name: "Springfield nursery")

        claim = create(
          :claim,
          policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
          first_name: "Claimant",
          surname: "Entered",
          date_of_birth: "1980-01-01",
          national_insurance_number: "AB123456C",
          eligibility_attributes: {
            eligible_eytfi_provider_urn: nursery.urn,
            teacher_auth_verified_name: "John Middle Doe",
            teacher_auth_verified_date_of_birth: "1970-12-13"
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
            fromDate: "2026-07-30",
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

        described_class.perform_now(claim)

        eligibility = claim.eligibility.reload
        expect(eligibility.hmrc_response_status).to eq(200)
        expect(eligibility.hmrc_response_body).to eq(response_body)
        expect(matching_request).to have_been_requested.once
        expect(employment_request).to have_been_requested.once
      end

      it "handles missing employer information" do
        nursery = create(:eligible_eytfi_provider, name: "Springfield nursery")

        claim = create(
          :claim,
          policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
          first_name: "Claimant",
          surname: "Entered",
          date_of_birth: "1980-01-01",
          national_insurance_number: "AB123456C",
          eligibility_attributes: {
            eligible_eytfi_provider_urn: nursery.urn,
            teacher_auth_verified_name: "John Middle Doe",
            teacher_auth_verified_date_of_birth: "1970-12-13"
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
            fromDate: "2026-07-30",
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

        described_class.perform_now(claim)

        eligibility = claim.eligibility.reload
        expect(eligibility.hmrc_response_status).to eq(200)
        expect(eligibility.hmrc_response_body).to eq(response_body)
        expect(matching_request).to have_been_requested.once
        expect(employment_request).to have_been_requested.once
      end

      it "handles a missing employer name" do
        nursery = create(:eligible_eytfi_provider, name: "Springfield nursery")

        claim = create(
          :claim,
          policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
          first_name: "Claimant",
          surname: "Entered",
          date_of_birth: "1980-01-01",
          national_insurance_number: "AB123456C",
          eligibility_attributes: {
            eligible_eytfi_provider_urn: nursery.urn,
            teacher_auth_verified_name: "John Middle Doe",
            teacher_auth_verified_date_of_birth: "1970-12-13"
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
            fromDate: "2026-07-30",
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

        described_class.perform_now(claim)

        eligibility = claim.eligibility.reload
        expect(eligibility.hmrc_response_status).to eq(200)
        expect(eligibility.hmrc_response_body).to eq(response_body)
        expect(matching_request).to have_been_requested.once
        expect(employment_request).to have_been_requested.once
      end
    end
  end

  context "when the HMRC API call succeeds" do
    context "when the claimant is employed at the setting" do
      it "stores employment history when employment dates are absent" do
        nursery = create(:eligible_eytfi_provider, name: "Springfield nursery")

        claim = create(
          :claim,
          policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
          first_name: "Claimant",
          surname: "Entered",
          date_of_birth: "1980-01-01",
          national_insurance_number: "AB123456C",
          eligibility_attributes: {
            eligible_eytfi_provider_urn: nursery.urn,
            teacher_auth_verified_name: "John Middle Doe",
            teacher_auth_verified_date_of_birth: "1970-12-13"
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
              name: "Springfield nursery",
              address: {
                postcode: nursery.postcode
              }
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
            fromDate: "2026-07-30",
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

        described_class.perform_now(claim)

        eligibility = claim.eligibility.reload
        expect(eligibility.hmrc_response_status).to eq(200)
        expect(eligibility.hmrc_response_body).to eq(response_body)
        expect(matching_request).to have_been_requested.once
        expect(employment_request).to have_been_requested.once
      end

      it "stores employment history regardless of employment dates" do
        nursery = create(:eligible_eytfi_provider, name: "Springfield nursery")

        claim = create(
          :claim,
          policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
          first_name: "Claimant",
          surname: "Entered",
          date_of_birth: "1980-01-01",
          national_insurance_number: "AB123456C",
          eligibility_attributes: {
            eligible_eytfi_provider_urn: nursery.urn,
            teacher_auth_verified_name: "John Middle Doe",
            teacher_auth_verified_date_of_birth: "1970-12-13"
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
              name: "Springfield nursery",
              address: {
                postcode: nursery.postcode
              }
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
            fromDate: "2026-07-30",
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

        described_class.perform_now(claim)

        eligibility = claim.eligibility.reload
        expect(eligibility.hmrc_response_status).to eq(200)
        expect(eligibility.hmrc_response_body).to eq(response_body)
        expect(matching_request).to have_been_requested.once
        expect(employment_request).to have_been_requested.once
      end
    end

    context "when the claimant is not employed at the setting" do
      it "stores employment at another setting" do
        nursery = create(:eligible_eytfi_provider, name: "Springfield nursery")

        claim = create(
          :claim,
          policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
          first_name: "Claimant",
          surname: "Entered",
          date_of_birth: "1980-01-01",
          national_insurance_number: "AB123456C",
          eligibility_attributes: {
            eligible_eytfi_provider_urn: nursery.urn,
            teacher_auth_verified_name: "John Middle Doe",
            teacher_auth_verified_date_of_birth: "1970-12-13"
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
            fromDate: "2026-07-30",
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

        described_class.perform_now(claim)

        eligibility = claim.eligibility.reload
        expect(eligibility.hmrc_response_status).to eq(200)
        expect(eligibility.hmrc_response_body).to eq(response_body)
        expect(matching_request).to have_been_requested.once
        expect(employment_request).to have_been_requested.once
      end

      it "stores an empty employment history" do
        nursery = create(:eligible_eytfi_provider, name: "Springfield nursery")

        claim = create(
          :claim,
          policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
          first_name: "Claimant",
          surname: "Entered",
          date_of_birth: "1980-01-01",
          national_insurance_number: "AB123456C",
          eligibility_attributes: {
            eligible_eytfi_provider_urn: nursery.urn,
            teacher_auth_verified_name: "John Middle Doe",
            teacher_auth_verified_date_of_birth: "1970-12-13"
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
            fromDate: "2026-07-30",
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

        described_class.perform_now(claim)

        eligibility = claim.eligibility.reload
        expect(eligibility.hmrc_response_status).to eq(200)
        expect(eligibility.hmrc_response_body).to eq(response_body)
        expect(matching_request).to have_been_requested.once
        expect(employment_request).to have_been_requested.once
      end
    end
  end

  context "when the job has already completed" do
    it "preserves the stored result without making HTTP requests" do
      claim = create(
        :claim,
        policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
        eligibility_attributes: {
          hmrc_response_status: 200,
          hmrc_response_body: {employments: []}.to_json
        }
      )
      original_attributes = claim.eligibility.attributes

      described_class.perform_now(claim)

      expect(claim.eligibility.reload.attributes).to eq(original_attributes)
      expect(a_request(:any, /service\.hmrc\.gov\.uk/)).not_to have_been_made
    end

    it "skips HTTP requests when only a status is stored" do
      claim = create(
        :claim,
        policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
        eligibility_attributes: {
          hmrc_response_status: 404
        }
      )
      original_attributes = claim.eligibility.attributes

      described_class.perform_now(claim)

      expect(claim.eligibility.reload.attributes).to eq(original_attributes)
      expect(a_request(:any, /service\.hmrc\.gov\.uk/)).not_to have_been_made
    end
  end
end
