require "rails_helper"

RSpec.describe "Claims", type: :request do
  describe "claims#new request" do
    before { create(:journey_configuration, :student_loans) }

    context "the user has not already started a claim" do
      it "renders the first page in the sequence" do
        get new_claim_path(StudentLoans.routing_name)
        follow_redirect!
        expect(response.body).to include("Use DfE Identity to sign in")
      end
    end

    it "redirects to the existing claim interruption page if another claim for the same policy is already in progress" do
      start_student_loans_claim
      get new_claim_path(StudentLoans.routing_name)

      expect(response).to redirect_to(existing_session_path(StudentLoans.routing_name))
    end

    context "switching claim policies" do
      before { create(:journey_configuration, :additional_payments) }

      it "redirects to the existing claim interruption page if a claim for another policy is already in progress" do
        start_student_loans_claim
        get new_claim_path(Policies::EarlyCareerPayments.routing_name)

        expect(response).to redirect_to(existing_session_path(Policies::EarlyCareerPayments.routing_name))
      end
    end
  end

  describe "claims#create request" do
    def check_claims_created
      expect { start_claim(@journey_configuration.routing_name) }.to change { Claim.count }.by(@journey_configuration.policies.count)
    end

    def check_claims_eligibility_created
      claims = @journey_configuration.policies.map { |p| Claim.by_policy(p).order(:created_at).last }
      current_claim = CurrentClaim.new(claims: claims)

      current_claim.claims.each_with_index do |claim, i|
        expect(claim.eligibility).to be_kind_of("#{@journey_configuration.policies[i]}::Eligibility".constantize)
        expect(claim.academic_year).to eq(@journey_configuration.current_academic_year)
      end
    end

    def check_slug_redirection
      expect(response).to redirect_to(claim_path(@journey_configuration.routing_name, @journey_configuration.slugs.first))
    end

    context "student loans claim" do
      it "created for the current academic year and redirects to the next question in the sequence" do
        @journey_configuration = create(:journey_configuration, :student_loans)

        check_claims_created
        check_claims_eligibility_created
        check_slug_redirection
      end
    end

    context "ecp and lup combined claim" do
      it "created for the current academic year and redirects to the next question in the sequence" do
        @journey_configuration = create(:journey_configuration, :additional_payments)

        check_claims_created
        check_claims_eligibility_created
        check_slug_redirection
      end
    end
  end

  describe "claims#show request" do
    before { create(:journey_configuration, :student_loans) }

    context "when a claim is already in progress" do
      let(:in_progress_claim) { Claim.by_policy(StudentLoans).order(:created_at).last }

      before { start_student_loans_claim }

      context "when the user has not completed the journey in the correct slug sequence" do
        it "redirects to the correct page in the sequence" do
          get claim_path(StudentLoans.routing_name, "sign-in-or-continue")
          expect(response.body).to include("Use DfE Identity to sign in")

          get claim_path(StudentLoans.routing_name, "claim-school")
          expect(response).to redirect_to(claim_path(StudentLoans.routing_name, "qts-year"))
        end
      end

      context "when the user has completed the journey in the correct slug sequence" do
        before { set_slug_sequence_in_session(in_progress_claim, "claim-school") }

        it "renders the requested page in the sequence" do
          get claim_path(StudentLoans.routing_name, "claim-school")
          expect(response.body).to include("Which school were you employed to teach at")
        end

        context "when searching for a school on the claim-school page" do
          let!(:school_1) { create(:school) }
          let!(:school_2) { create(:school) }

          it "searches for schools using the search term" do
            get claim_path(StudentLoans.routing_name, "claim-school"), params: {school_search: school_1.name}

            # Issues with e.g. "O&#39;Kon and Sons School" matching "O'Kon and Sons School", quickfix escape html
            expect(response.body).to include CGI.escapeHTML(school_1.name)
            expect(response.body).not_to include CGI.escapeHTML(school_2.name)

            expect(response.body).to include "Continue"
          end

          it "only returns results if the search term is more than two characters" do
            get claim_path(StudentLoans.routing_name, "claim-school"), params: {school_search: "ab"}

            expect(response.body).to include("There is a problem")
            expect(response.body).to include("Enter a school or postcode")
            expect(response.body).not_to include(school_1.name)
          end

          it "shows an appropriate message when there are no search results" do
            get claim_path(StudentLoans.routing_name, "claim-school"), params: {school_search: "crocodile"}

            expect(response.body).to include("No results match that search term")
          end
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
    before { create(:journey_configuration, :student_loans) }

    context "when a claim is already in progress" do
      before { start_student_loans_claim }

      it "renders a static ineligibility page" do
        Claim.by_policy(StudentLoans).order(:created_at).last.eligibility.update(employment_status: "no_school")

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
    before { create(:journey_configuration, :student_loans) }

    it "displays session timeout content" do
      get timeout_claim_path(StudentLoans.routing_name)
      expect(response.body).to include("Your session has ended due to inactivity")
    end
  end

  describe "claims#update request" do
    before { create(:journey_configuration, :student_loans) }

    context "when a claim is already in progress" do
      let(:in_progress_claim) { Claim.by_policy(StudentLoans).order(:created_at).last }

      before {
        start_student_loans_claim
        set_slug_sequence_in_session(in_progress_claim, "qts-year")
      }

      it "updates the claim with the submitted form data" do
        put claim_path(StudentLoans.routing_name, "qts-year"), params: {claim: {eligibility_attributes: {qts_award_year: "on_or_after_cut_off_date"}}}

        expect(response).to redirect_to(claim_path(StudentLoans.routing_name, "claim-school"))
        expect(in_progress_claim.reload.eligibility.qts_award_year).to eq "on_or_after_cut_off_date"
      end

      it "makes sure validations appropriate to the context are run" do
        put claim_path(StudentLoans.routing_name, "qts-year"), params: {claim: {eligibility_attributes: {qts_award_year: nil}}}
        expect(response.body).to include("Select when you completed your initial teacher training")
      end

      context "when the user has not completed the journey in the correct slug sequence" do
        it "redirects to the start of the journey" do
          put claim_path(StudentLoans.routing_name, "student-loan"), params: {claim: {has_student_loan: true}}
          expect(response).to redirect_to(claim_path(StudentLoans.routing_name, "qts-year"))
        end
      end

      context "when the user has completed the journey in the correct slug sequence" do
        before { set_slug_sequence_in_session(in_progress_claim, "student-loan") }

        it "resets dependent claim attributes when appropriate" do
          in_progress_claim.update!(has_student_loan: false, student_loan_plan: Claim::NO_STUDENT_LOAN)
          put claim_path(StudentLoans.routing_name, "student-loan"), params: {claim: {has_student_loan: true}}

          expect(response).to redirect_to(claim_path(StudentLoans.routing_name, "student-loan-country"))
          expect(in_progress_claim.reload.student_loan_plan).to be_nil
        end
      end

      it "resets depenent eligibility attributes when appropriate" do
        in_progress_claim.update!(eligibility_attributes: {had_leadership_position: true, mostly_performed_leadership_duties: false})
        set_slug_sequence_in_session(in_progress_claim, "leadership-position")
        put claim_path(StudentLoans.routing_name, "leadership-position"), params: {claim: {eligibility_attributes: {had_leadership_position: false}}}

        expect(response).to redirect_to(claim_path(StudentLoans.routing_name, "eligibility-confirmed"))
        expect(in_progress_claim.eligibility.reload.mostly_performed_leadership_duties).to be_nil
      end

      context "having searched for a school but not selected a school from the results on the claim-school page" do
        let!(:school) { create(:school) }

        before { set_slug_sequence_in_session(in_progress_claim, "claim-school") }

        it "re-renders the school search results with an error message" do
          put claim_path(StudentLoans.routing_name, "claim-school"), params: {school_search: school.name, claim: {eligibility_attributes: {claim_school_id: ""}}}

          expect(response).to be_successful
          expect(response.body).to include("There is a problem")
          expect(response.body).to include("Select a school from the list")
          expect(response.body).to include(school.name)
        end
      end

      context "when the update makes the claim ineligible" do
        let(:ineligible_school) { create(:school, :student_loans_ineligible) }

        it "redirects to the “ineligible” page" do
          set_slug_sequence_in_session(in_progress_claim, "claim-school")
          put claim_path(StudentLoans.routing_name, "claim-school"), params: {claim: {eligibility_attributes: {claim_school_id: ineligible_school.to_param}}}

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

  # 2022/2023 onwards /additional-payments covers ECP and LUP claims
  describe "when navigating to /early-career-payments/* urls " do
    context "base url" do
      it "redirects to the additional-payments gov page" do
        get "/early-career-payments"
        expect(response).to redirect_to("https://www.gov.uk/government/collections/additional-payments-for-teaching-eligibility-and-payment-details")
      end
    end

    context "base url + trailing slash" do
      it "redirects to the additional-payments gov page" do
        get "/early-career-payments/"
        expect(response).to redirect_to("https://www.gov.uk/government/collections/additional-payments-for-teaching-eligibility-and-payment-details")
      end
    end

    context "base url + anything else" do
      it "redirects to the additional-payments gov page" do
        get "/early-career-payments/claim"
        expect(response).to redirect_to("https://www.gov.uk/government/collections/additional-payments-for-teaching-eligibility-and-payment-details")
      end
    end
  end
end
