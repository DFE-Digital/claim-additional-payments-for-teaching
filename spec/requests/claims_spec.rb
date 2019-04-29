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
      expect { post claims_path }.to change { TslrClaim.count }.by(1)

      expect(response).to redirect_to(claim_path(:qts_year))
    end
  end

  describe "claims#show request" do
    context "when a claim is already in progress" do
      let(:in_progress_claim) { TslrClaim.order(:created_at).last }

      before { post claims_path }

      it "renders the requested page in the sequence" do
        get claim_path(:qts_year)
        expect(response.body).to include("Which academic year were you awarded qualified teacher status")

        get claim_path(:claim_school)
        expect(response.body).to include("Which school were you employed at")
      end
    end

    context "when a claim hasn’t been started yet" do
      it "redirects to the start page" do
        get claim_path(:qts_year)
        expect(:response).to redirect_to(root_path)
      end
    end
  end

  describe "claims#update request" do
    context "when a claim is already in progress" do
      let(:in_progress_claim) { TslrClaim.order(:created_at).last }

      before { post claims_path }

      it "updates the claim with the submitted form data" do
        put claim_path(:qts_year), params: {tslr_claim: {qts_award_year: "2014-2015"}}

        expect(in_progress_claim.qts_award_year).to eq "2014-2015"
      end
    end

    context "when a claim hasn’t been started yet" do
      it "redirects to the start page" do
        put claim_path(:qts_year), params: {tslr_claim: {qts_award_year: "2014-2015"}}
        expect(:response).to redirect_to(root_path)
      end
    end
  end
end
