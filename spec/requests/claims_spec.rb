require "rails_helper"

RSpec.describe "Claims", type: :request do
  describe "claims#new request" do
    it "renders the consent form" do
      get new_claim_path

      expect(response).to be_successful
      expect(response.body).to include("Consent to us contacting your school")
    end
  end

  describe "claims#create request" do
    it "creates a new TslrClaim and redirects to the QTS question" do
      expect { post claim_path }.to change { TslrClaim.count }.by(1)

      expect(response).to redirect_to(qts_year_claim_path)
    end
  end

  describe "claims#update request" do
    context "when a claim is already in progress" do
      let(:in_progress_claim) { TslrClaim.order(:created_at).last }

      before { post claim_path }

      it "updates the claim with the submitted form data" do
        put claim_path, params: {tslr_claim: {qts_award_year: "2014-2015"}}

        expect(in_progress_claim.qts_award_year).to eq "2014-2015"
      end
    end
  end
end
