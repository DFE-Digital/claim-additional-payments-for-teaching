require "rails_helper"
require "verify/fake_sso"

RSpec.describe "GOV.UK Verify::AuthenticationsController requests", type: :request do
  context "when a claim is in progress" do
    before { start_claim }

    describe "verify/authentications/new" do
      before do
        stub_vsp_generate_request
        get new_verify_authentications_path
      end

      it "renders a form that will submit an authentication request to Verify" do
        expect(response.body).to include("action=\"#{stubbed_auth_request_response["ssoLocation"]}\"")
        expect(response.body).to include(stubbed_auth_request_response["samlRequest"])
      end

      it "stores the request_id in the user’s session" do
        expect(session[:verify_request_id]).to eql(stubbed_auth_request_response["requestId"])
      end
    end

    describe "POST verify/authentications (i.e. the verify callback handler)" do
      before do
        start_claim

        stub_vsp_generate_request
        get new_verify_authentications_path # sets the authentication request request_id in the session
      end

      let(:current_claim) { Claim.order(:created_at).last }

      context "given an IDENTITY_VERIFIED SAML response" do
        let(:saml_response) { Verify::FakeSso::IDENTITY_VERIFIED_SAML_RESPONSE }

        before do
          stub_vsp_translate_response_request
          post verify_authentications_path, params: {"SAMLResponse" => saml_response}
        end

        it "saves the translated identity attributes on the current claim and redirects to the verify confirmation" do
          expect(response).to redirect_to(claim_path(StudentLoans.routing_name, "verified"))

          expect(current_claim.first_name).to eq("Isambard")
          expect(current_claim.middle_name).to eq("Kingdom")
          expect(current_claim.surname).to eq("Brunel")
          expect(current_claim.address_line_1).to eq("Verified Building")
          expect(current_claim.address_line_2).to eq("Verified Street")
          expect(current_claim.address_line_3).to eq("Verified Town")
          expect(current_claim.address_line_4).to eq("Verified County")
          expect(current_claim.postcode).to eq("M12 345")
          expect(current_claim.date_of_birth).to eq(Date.new(1806, 4, 9))
          expect(current_claim.payroll_gender).to eq("male")

          expect(current_claim.verified_fields).to match_array([
            "first_name",
            "middle_name",
            "surname",
            "address_line_1",
            "address_line_2",
            "address_line_3",
            "address_line_4",
            "postcode",
            "date_of_birth",
            "payroll_gender",
          ])
        end
      end

      context "given an AUTHENTICATION_FAILURE SAML response" do
        let(:saml_response) { example_vsp_translate_request_payload.fetch("samlResponse") }

        before do
          stub_vsp_translate_response_request("authentication-failed")
          post verify_authentications_path, params: {"SAMLResponse" => saml_response}
        end

        it "redirects to the failure page" do
          expect(response).to redirect_to(failed_verify_authentications_path)
        end
      end

      context "given a NO_AUTHENTICATION SAML response" do
        let(:saml_response) { example_vsp_translate_request_payload.fetch("samlResponse") }

        before do
          stub_vsp_translate_response_request("no-authentication")
          post verify_authentications_path, params: {"SAMLResponse" => saml_response}
        end

        it "redirects to the no_auth page" do
          expect(response).to redirect_to(no_auth_verify_authentications_path)
        end
      end
    end
  end

  describe "GET verify/authentications/failed" do
    before { start_claim }

    it "renders the failure content" do
      get failed_verify_authentications_path

      expect(response).to be_successful
      expect(response.body).to include("the company you chose does not have enough information about you")
    end
  end

  describe "GET verify/authentications/no_auth" do
    before { start_claim }

    it "renders the no-auth content" do
      get no_auth_verify_authentications_path

      expect(response).to be_successful
      expect(response.body).to include("you did not complete the process")
    end
  end

  context "when a claim hasn’t been started yet" do
    before { stub_vsp_generate_request }

    it "redirects to the start page" do
      get new_verify_authentications_path
      expect(response).to redirect_to(StudentLoans.start_page_url)

      post verify_authentications_path
      expect(response).to redirect_to(StudentLoans.start_page_url)
    end
  end
end
