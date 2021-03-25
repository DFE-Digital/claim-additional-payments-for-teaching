require "rails_helper"

RSpec.describe "Claims", type: :request do
  describe "claims#new request" do
    context "the user has not already started a claim" do
      it "renders the first page in the sequence" do
        get new_claim_path(StudentLoans.routing_name)
        expect(response.body).to include(I18n.t("questions.qts_award_year"))
      end
    end

    it "redirects to the existing claim interruption page if a claim for another policy is already in progress" do
      start_student_loans_claim
      get new_claim_path(MathsAndPhysics.routing_name)

      expect(response).to redirect_to(existing_session_path(MathsAndPhysics.routing_name))
    end

    it "redirects to the existing claim interruption page if another claim for the same policy is already in progress" do
      start_student_loans_claim
      get new_claim_path(StudentLoans.routing_name)

      expect(response).to redirect_to(existing_session_path(StudentLoans.routing_name))
    end
  end

  describe "claims#create request" do
    Policies.all.each do |policy|
      it "creates a new #{policy.name} claim for the current academic year and redirects to the next question in the sequence" do
        expect { start_claim(policy) }.to change { Claim.count }.by(1)

        claim = Claim.last
        current_academic_year = policy_configurations(policy.locale_key).current_academic_year

        expect(claim.eligibility).to be_kind_of(policy::Eligibility)
        expect(claim.academic_year).to eq(current_academic_year)

        expect(response).to redirect_to(claim_path(policy.routing_name, policy::SlugSequence::SLUGS[1]))
      end

      it "does not create a #{policy.name} claim if validations fail" do
        expect { post claims_path(policy.routing_name) }.not_to change { Claim.count }
        expect(response.body).to include("There is a problem")
      end
    end
  end

  describe "claims#show request" do
    context "when a claim is already in progress" do
      before { start_student_loans_claim }

      it "renders the requested page in the sequence" do
        get claim_path(StudentLoans.routing_name, "qts-year")
        expect(response.body).to include(I18n.t("questions.qts_award_year"))

        get claim_path(StudentLoans.routing_name, "claim-school")
        expect(response.body).to include("Which school were you employed to teach at")
      end

      context "when searching for a school on the claim-school page" do
        it "searches for schools using the search term" do
          get claim_path(StudentLoans.routing_name, "claim-school"), params: {school_search: "Penistone"}

          expect(response.body).to include schools(:penistone_grammar_school).name
          expect(response.body).not_to include schools(:hampstead_school).name
          expect(response.body).to include "Continue"
        end

        it "only returns results if the search term is more than two characters" do
          get claim_path(StudentLoans.routing_name, "claim-school"), params: {school_search: "Pe"}

          expect(response.body).to include("There is a problem")
          expect(response.body).to include("Enter the name or postcode of the school")
          expect(response.body).not_to include(schools(:penistone_grammar_school).name)
        end

        it "shows an appropriate message when there are no search results" do
          get claim_path(StudentLoans.routing_name, "claim-school"), params: {school_search: "crocodile"}

          expect(response.body).to include("No results match that search term")
        end
      end
    end

    context "when a claim hasn’t been started yet" do
      it "redirects to the start page indicated by the routing" do
        get claim_path(StudentLoans.routing_name, "qts-year")
        expect(response).to redirect_to(StudentLoans.start_page_url)
      end
    end
  end

  describe "the claims ineligible page" do
    context "when a claim is already in progress" do
      before { start_student_loans_claim }

      it "renders a static ineligibility page" do
        Claim.order(:created_at).last.eligibility.update(employment_status: "no_school")

        get claim_path(StudentLoans.routing_name, "ineligible")

        expect(response.body).to include("You’re not eligible")
        expect(response.body).to include("You can only get this payment if you’re still employed to teach at a state-funded secondary school.")
      end
    end

    context "when a claim hasn’t been started yet" do
      it "redirects to the start page indicated by the routing" do
        get claim_path(StudentLoans.routing_name, "ineligible")
        expect(response).to redirect_to(StudentLoans.start_page_url)
      end
    end
  end

  describe "claims#timeout" do
    it "displays session timeout content" do
      get timeout_claim_path(StudentLoans.routing_name)
      expect(response.body).to include("Your session has ended due to inactivity")
    end
  end

  describe "claims#update request" do
    context "when a claim is already in progress" do
      let(:in_progress_claim) { Claim.order(:created_at).last }

      before { start_student_loans_claim }

      it "updates the claim with the submitted form data" do
        put claim_path(StudentLoans.routing_name, "qts-year"), params: {claim: {eligibility_attributes: {qts_award_year: "on_or_after_cut_off_date"}}}

        expect(in_progress_claim.eligibility.qts_award_year).to eq "on_or_after_cut_off_date"
      end

      it "makes sure validations appropriate to the context are run" do
        put claim_path(StudentLoans.routing_name, "qts-year"), params: {claim: {eligibility_attributes: {qts_award_year: nil}}}

        expect(response.body).to include("Select when you completed your initial teacher training")
      end

      it "resets dependent claim attributes when appropriate" do
        in_progress_claim.update!(has_student_loan: false, student_loan_plan: Claim::NO_STUDENT_LOAN)
        put claim_path(StudentLoans.routing_name, "student-loan"), params: {claim: {has_student_loan: true}}

        expect(response).to redirect_to(claim_path(StudentLoans.routing_name, "student-loan-country"))
        expect(in_progress_claim.reload.student_loan_plan).to be_nil
      end

      it "resets depenent eligibility attributes when appropriate" do
        in_progress_claim.update!(eligibility_attributes: {had_leadership_position: true, mostly_performed_leadership_duties: false})
        put claim_path(StudentLoans.routing_name, "leadership-position"), params: {claim: {eligibility_attributes: {had_leadership_position: false}}}

        expect(response).to redirect_to(claim_path(StudentLoans.routing_name, "eligibility-confirmed"))
        expect(in_progress_claim.eligibility.reload.mostly_performed_leadership_duties).to be_nil
      end

      context "having searched for a school but not selected a school from the results on the claim-school page" do
        it "re-renders the school search results with an error message" do
          put claim_path(StudentLoans.routing_name, "claim-school"), params: {school_search: "peniston", claim: {eligibility_attributes: {claim_school_id: ""}}}

          expect(response).to be_successful
          expect(response.body).to include("There is a problem")
          expect(response.body).to include("Select a school from the list")
          expect(response.body).to include(schools(:penistone_grammar_school).name)
        end
      end

      context "when the update makes the claim ineligible" do
        it "redirects to the “ineligible” page" do
          put claim_path(StudentLoans.routing_name, "claim-school"), params: {claim: {eligibility_attributes: {claim_school_id: schools(:hampstead_school).to_param}}}

          expect(response).to redirect_to(claim_path(StudentLoans.routing_name, "ineligible"))
        end
      end
    end

    context "when a claim hasn’t been started yet" do
      it "redirects to the start page indicated by the routing" do
        put claim_path(StudentLoans.routing_name, "qts-year"), params: {claim: {eligibility_attributes: {qts_award_year: "on_or_after_cut_off_date"}}}
        expect(response).to redirect_to(StudentLoans.start_page_url)
      end
    end
  end
end
