require "rails_helper"

RSpec.describe "Claim session timing out", type: :request do
  let(:timeout_length_in_minutes) { BasePublicController::CLAIM_TIMEOUT_LENGTH_IN_MINUTES }

  context "no actions performed for more than the timeout period" do
    before do
      start_claim
      start_verify_authentication_process
    end

    let(:current_claim) { Claim.order(:created_at).last }
    let(:after_expiry) { timeout_length_in_minutes.minutes + 1.second }

    it "clears the session and redirects to the timeout page" do
      expect(session[:claim_id]).to eql current_claim.to_param
      expect(session[:verify_request_id]).not_to be_nil

      travel after_expiry do
        put claim_path("qts-year"), params: {claim: {qts_award_year: "on_or_after_september_2013"}}

        expect(response).to redirect_to(timeout_claim_path)
        expect(session[:claim_id]).to be_nil
        expect(session[:verify_request_id]).to be_nil
      end
    end
  end

  context "no action performed just within the timeout period" do
    before do
      start_claim
      start_verify_authentication_process
    end

    let(:current_claim) { Claim.order(:created_at).last }
    let(:before_expiry) { timeout_length_in_minutes.minutes - 2.seconds }

    it "does not timeout the session" do
      travel before_expiry do
        put claim_path("qts-year"), params: {claim: {eligibility_attributes: {qts_award_year: "on_or_after_september_2013"}}}

        expect(response).to redirect_to(claim_path("claim-school"))
        expect(session[:verify_request_id]).not_to be_nil
      end
    end
  end

  private

  def start_verify_authentication_process
    stub_vsp_generate_request
    get new_verify_authentications_path
  end
end
