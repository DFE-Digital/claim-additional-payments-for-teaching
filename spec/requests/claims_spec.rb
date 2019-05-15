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

      expect(response).to redirect_to(claim_path("qts-year"))
    end
  end

  describe "claims#show request" do
    context "when a claim is already in progress" do
      before { post claims_path }

      it "renders the requested page in the sequence" do
        get claim_path("qts-year")
        expect(response.body).to include("Which academic year were you awarded qualified teacher status")

        get claim_path("claim-school")
        expect(response.body).to include("Which school were you employed at")
      end

      context "when searching for a school on the claim-school page" do
        it "searchers for schools using the search term" do
          get claim_path("claim-school"), params: {school_search: "Penistone"}

          expect(response.body).to include schools(:penistone_grammar_school).name
          expect(response.body).not_to include schools(:hampstead_school).name
          expect(response.body).to include "Continue"
        end

        it "only returns results if the search term is more than three characters" do
          get claim_path("claim-school"), params: {school_search: "Pen"}

          expect(response.body).to include("There is a problem")
          expect(response.body).to include("Search for the school name with a minimum of four characters")
          expect(response.body).not_to include(schools(:penistone_grammar_school).name)
        end

        it "shows an appropriate message when there are no search results" do
          get claim_path("claim-school"), params: {school_search: "crocodile"}

          expect(response.body).to include("No results match that search term")
        end
      end
    end

    context "when a claim hasn’t been started yet" do
      it "redirects to the start page" do
        get claim_path("qts-year")
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "claim#ineligible request" do
    context "when a claim is already in progress" do
      before { post claims_path }

      it "renders a static ineligibility page" do
        get ineligible_claim_path
        expect(response.body).to include("You’re not eligible")
      end
    end

    context "when a claim hasn’t been started yet" do
      it "redirects to the start page" do
        get ineligible_claim_path
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "claims#update request" do
    context "when a claim is already in progress" do
      let(:in_progress_claim) { TslrClaim.order(:created_at).last }

      before { post claims_path }

      it "updates the claim with the submitted form data" do
        put claim_path("qts-year"), params: {tslr_claim: {qts_award_year: "2014-2015"}}

        expect(in_progress_claim.qts_award_year).to eq "2014-2015"
      end

      it "makes sure validations appropriate to the context are run" do
        put claim_path("qts-year"), params: {tslr_claim: {qts_award_year: nil}}

        expect(response.body).to include("Select the academic year you were awarded qualified teacher status")
      end

      context "having searched for a school but not selected a school from the results on the claim-school page" do
        it "re-renders the school search results with an error message" do
          put claim_path("claim-school"), params: {school_search: "peniston", tslr_claim: {claim_school_id: ""}}

          expect(response).to be_successful
          expect(response.body).to include("There is a problem")
          expect(response.body).to include("Select a school from the list")
          expect(response.body).to include(schools(:penistone_grammar_school).name)
        end
      end
    end

    context "when a claim hasn’t been started yet" do
      it "redirects to the start page" do
        put claim_path("qts-year"), params: {tslr_claim: {qts_award_year: "2014-2015"}}
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
