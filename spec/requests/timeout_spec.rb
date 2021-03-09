require "rails_helper"

RSpec.describe "Claim session timing out", type: :request do
  let(:timeout_length_in_minutes) { BasePublicController::CLAIM_TIMEOUT_LENGTH_IN_MINUTES }

  context "no actions performed for more than the timeout period" do
    before do
      start_student_loans_claim
    end

    let(:current_claim) { Claim.order(:created_at).last }
    let(:after_expiry) { timeout_length_in_minutes.minutes + 1.second }

    it "clears the session and redirects to the timeout page" do
      expect(session[:claim_id]).to eql current_claim.to_param

      travel after_expiry do
        put claim_path(StudentLoans.routing_name, "qts-year"), params: {claim: {qts_award_year: "on_or_after_cut_off_date"}}

        expect(response).to redirect_to(timeout_claim_path)
        expect(session[:claim_id]).to be_nil
      end
    end
  end

  context "no action performed just within the timeout period" do
    before do
      start_student_loans_claim
    end

    let(:current_claim) { Claim.order(:created_at).last }
    let(:before_expiry) { timeout_length_in_minutes.minutes - 2.seconds }

    it "does not timeout the session" do
      travel before_expiry do
        put claim_path(StudentLoans.routing_name, "qts-year"), params: {claim: {eligibility_attributes: {qts_award_year: "on_or_after_cut_off_date"}}}

        expect(response).to redirect_to(claim_path(StudentLoans.routing_name, "claim-school"))
      end
    end
  end
end
