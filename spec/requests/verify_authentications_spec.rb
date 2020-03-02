require "rails_helper"
require "verify/fake_sso"

RSpec.describe "GOV.UK Verify::AuthenticationsController requests", type: :request do
  context "when a claim is in progress" do
    before { start_student_loans_claim }

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

      it "returns cache headers so the page gives a newly minted VSP request on every visit" do
        expect(response.headers["Cache-Control"]).to eq("no-cache, no-store")
        expect(response.headers["Pragma"]).to eq("no-cache")
        expect(response.headers["Expires"]).to eq("Fri, 01 Jan 1990 00:00:00 GMT")
      end
    end

    describe "POST verify/authentications (i.e. the verify callback handler)" do
      before do
        start_student_loans_claim

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
          expect(current_claim.address_line_1).to eq("Unverified Street")
          expect(current_claim.address_line_2).to eq("Unverified Town")
          expect(current_claim.address_line_3).to eq("Unverified County")
          expect(current_claim.postcode).to eq("L12 345")
          expect(current_claim.date_of_birth).to eq(Date.new(1806, 4, 9))
          expect(current_claim.payroll_gender).to eq("male")

          expect(current_claim.govuk_verify_fields).to match_array([
            "first_name",
            "middle_name",
            "surname",
            "address_line_1",
            "address_line_2",
            "address_line_3",
            "postcode",
            "date_of_birth",
            "payroll_gender"
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
    before { start_student_loans_claim }

    it "renders the failure content" do
      get failed_verify_authentications_path

      expect(response).to be_successful
      expect(response.body).to include("the company you chose does not have enough information about you")
    end
  end

  describe "GET verify/authentications/no_auth" do
    before { start_student_loans_claim }

    it "renders the no-auth content" do
      get no_auth_verify_authentications_path

      expect(response).to be_successful
      expect(response.body).to include("you did not complete the process")
    end
  end

  describe "verify/authentications/skip" do
    before { start_student_loans_claim }

    it "redirects the user to the “name” page for their claim" do
      get skip_verify_authentications_path

      expect(response).to redirect_to(claim_path(StudentLoans.routing_name, "name"))
    end
  end

  context "when a claim hasn’t been started yet" do
    before { stub_vsp_generate_request }

    it "redirects to the root of the service, as we have no way to identify a specific policy to redirect them to" do
      get new_verify_authentications_path
      expect(response).to redirect_to(root_url)

      post verify_authentications_path
      expect(response).to redirect_to(root_url)
    end
  end
end
