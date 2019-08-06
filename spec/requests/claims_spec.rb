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
        expect(response.body).to include(I18n.t("tslr.questions.qts_award_year"))

        get claim_path("claim-school")
        expect(response.body).to include("Which school were you employed at")
      end

      context "when searching for a school on the claim-school page" do
        it "searches for schools using the search term" do
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

    context "when the user reaches the confirmation page after submitting their claim" do
      before do
        post claims_path

        claim = TslrClaim.order(:created_at).last
        claim.update_attributes(attributes_for(:tslr_claim, :submittable))
        claim.eligibility.update_attributes(attributes_for(:student_loans_eligibility, :submittable))

        claim.submit!

        get claim_path("confirmation")
      end

      it "clears the claim from the session" do
        expect(session[:tslr_claim_id]).to be_nil
        expect(session[:last_seen_at]).to be_nil
      end
    end
  end

  describe "the claims ineligible page" do
    context "when a claim is already in progress" do
      before { post claims_path }

      it "renders a static ineligibility page" do
        get claim_path("ineligible")
        expect(response.body).to include("You’re not eligible")
      end

      it "tailors the message to the claim" do
        TslrClaim.order(:created_at).last.eligibility.update(employment_status: "no_school")

        get claim_path("ineligible")
        expect(response.body).to include("You’re not eligible")
        expect(response.body).to include("You can only get this payment if you’re still working as a teacher")
      end
    end

    context "when a claim hasn’t been started yet" do
      it "redirects to the start page" do
        get claim_path("ineligible")
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "claims#timeout" do
    it "displays session timeout content" do
      get timeout_claim_path
      expect(response.body).to include("Your session has ended due to inactivity")
    end
  end

  describe "claim#refresh_session" do
    it "updates the last seen at timestamp" do
      freeze_time do
        get claim_refresh_session_path
        expect(session[:last_seen_at]).to eql(Time.zone.now)
      end
    end

    it "gives a successful response" do
      get claim_refresh_session_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "claims#update request" do
    context "when a claim is already in progress" do
      let(:in_progress_claim) { TslrClaim.order(:created_at).last }

      before { post claims_path }

      it "updates the claim with the submitted form data" do
        put claim_path("qts-year"), params: {tslr_claim: {eligibility_attributes: {qts_award_year: "2014_2015"}}}

        expect(in_progress_claim.qts_award_year).to eq "2014_2015"
      end

      it "makes sure validations appropriate to the context are run" do
        put claim_path("qts-year"), params: {tslr_claim: {eligibility_attributes: {qts_award_year: nil}}}

        expect(response.body).to include("Select the academic year you were awarded qualified teacher status")
      end

      context "having searched for a school but not selected a school from the results on the claim-school page" do
        it "re-renders the school search results with an error message" do
          put claim_path("claim-school"), params: {school_search: "peniston", tslr_claim: {eligibility_attributes: {claim_school_id: ""}}}

          expect(response).to be_successful
          expect(response.body).to include("There is a problem")
          expect(response.body).to include("Select a school from the list")
          expect(response.body).to include(schools(:penistone_grammar_school).name)
        end
      end

      context "when the update makes the claim ineligible" do
        it "redirects to the “ineligible” page" do
          put claim_path("claim-school"), params: {tslr_claim: {eligibility_attributes: {claim_school_id: schools(:hampstead_school).to_param}}}

          expect(response).to redirect_to(claim_path("ineligible"))
        end
      end

      context "when a field has come from Verify" do
        before do
          in_progress_claim.update!(verified_fields: ["payroll_gender"])
        end

        it "raises an error when trying to update via the controller" do
          expect {
            put claim_path("claim-school"), params: {tslr_claim: {payroll_gender: "female"}}
          }.to raise_error(
            ActionController::UnpermittedParameters
          )
        end
      end

      context "when updating from check-your-answers" do
        context "with a submittable claim" do
          before :each do
            # Make the claim submittable
            in_progress_claim.update!(attributes_for(:tslr_claim, :submittable))
            in_progress_claim.eligibility.update!(attributes_for(:student_loans_eligibility, :submittable))

            perform_enqueued_jobs do
              put claim_path("check-your-answers")
            end

            in_progress_claim.reload
          end

          it "submits the claim" do
            expect(in_progress_claim.submitted_at).to be_present
          end

          it "sends an email" do
            email = ActionMailer::Base.deliveries.first
            expect(email.to).to eql([in_progress_claim.email_address])
            expect(email.subject).to eql("Your claim was received")
            expect(email.body).to include("Your reference number is #{in_progress_claim.reference}")
          end

          it "redirects to the confirmation page" do
            expect(response).to redirect_to(claim_path("confirmation"))
          end
        end

        context "with an unsubmittable claim" do
          before :each do
            # Make the claim _almost_ submittable
            in_progress_claim.update!(attributes_for(:tslr_claim, :submittable, email_address: nil))

            put claim_path("check-your-answers")

            in_progress_claim.reload
          end

          it "doesn't submit the claim" do
            expect(in_progress_claim.submitted_at).to be_nil
          end

          it "doesn't send an email" do
            expect(ActionMailer::Base.deliveries).to be_empty
          end

          it "re-renders the check-your-answers page with errors" do
            expect(response.body).to include("Check your answers before sending your application")
            expect(response.body).to include("Enter an email address")
          end
        end
      end
    end

    context "when a claim hasn’t been started yet" do
      it "redirects to the start page" do
        put claim_path("qts-year"), params: {tslr_claim: {eligibility_attributes: {qts_award_year: "2014_2015"}}}
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
