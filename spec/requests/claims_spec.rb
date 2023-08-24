require "rails_helper"

RSpec.describe "Claims", type: :request do
  include DqtApiHelper

  describe "claims#new request" do
    before { create(:policy_configuration, :student_loans) }

    context "the user has not already started a claim" do
      it "renders the first page in the sequence" do
        get new_claim_path(StudentLoans.routing_name)
        follow_redirect!
        expect(response.body).to include(I18n.t("questions.qts_award_year"))
      end
    end

    it "redirects to the existing claim interruption page if another claim for the same policy is already in progress" do
      start_student_loans_claim
      get new_claim_path(StudentLoans.routing_name)

      expect(response).to redirect_to(existing_session_path(StudentLoans.routing_name))
    end

    context "switching claim policies" do
      before { create(:policy_configuration, :maths_and_physics) }

      it "redirects to the existing claim interruption page if a claim for another policy is already in progress" do
        start_student_loans_claim
        get new_claim_path(MathsAndPhysics.routing_name)

        expect(response).to redirect_to(existing_session_path(MathsAndPhysics.routing_name))
      end
    end
  end

  describe "claims#create request" do
    def check_claims_created
      expect { start_claim(@policy_configuration.routing_name) }.to change { Claim.count }.by(@policy_configuration.policies.count)
    end

    def check_claims_eligibility_created
      claims = @policy_configuration.policies.map { |p| Claim.by_policy(p).order(:created_at).last }
      current_claim = CurrentClaim.new(claims: claims)

      current_claim.claims.each_with_index do |claim, i|
        expect(claim.eligibility).to be_kind_of(@policy_configuration.policies[i]::Eligibility)
        expect(claim.academic_year).to eq(@policy_configuration.current_academic_year)
      end
    end

    def check_slug_redirection
      expect(response).to redirect_to(claim_path(@policy_configuration.routing_name, @policy_configuration.slugs.first))
    end

    context "student loans claim" do
      it "created for the current academic year and redirects to the next question in the sequence" do
        @policy_configuration = create(:policy_configuration, :student_loans)

        check_claims_created
        check_claims_eligibility_created
        check_slug_redirection
      end
    end

    context "maths and physics claim" do
      it "created for the current academic year and redirects to the next question in the sequence" do
        @policy_configuration = create(:policy_configuration, :maths_and_physics)

        check_claims_created
        check_claims_eligibility_created
        check_slug_redirection
      end
    end

    context "ecp and lup combined claim" do
      it "created for the current academic year and redirects to the next question in the sequence" do
        @policy_configuration = create(:policy_configuration, :additional_payments)

        check_claims_created
        check_claims_eligibility_created
        check_slug_redirection
      end
    end
  end

  describe "claims#show request" do
    before { create(:policy_configuration, :student_loans) }

    context "when a claim is already in progress" do
      let(:in_progress_claim) { Claim.by_policy(StudentLoans).order(:created_at).last }

      before { start_student_loans_claim }

      context "when the user has not completed the journey in the correct slug sequence" do
        it "redirects to the correct page in the sequence" do
          get claim_path(StudentLoans.routing_name, "qts-year")
          expect(response.body).to include(I18n.t("questions.qts_award_year"))

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

            expect(response.body).to include school_1.name
            expect(response.body).not_to include school_2.name
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
    before { create(:policy_configuration, :student_loans) }

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
    before { create(:policy_configuration, :student_loans) }

    it "displays session timeout content" do
      get timeout_claim_path(StudentLoans.routing_name)
      expect(response.body).to include("Your session has ended due to inactivity")
    end
  end

  describe "claims#update request" do
    before { create(:policy_configuration, :student_loans) }

    context "when a claim is already in progress" do
      let(:in_progress_claim) { Claim.by_policy(StudentLoans).order(:created_at).last }

      before { start_student_loans_claim }

      it "updates the claim with the submitted form data" do
        put claim_path(StudentLoans.routing_name, "qts-year"), params: {claim: {eligibility_attributes: {qts_award_year: "on_or_after_cut_off_date"}}}

        expect(in_progress_claim.eligibility.qts_award_year).to eq "on_or_after_cut_off_date"
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

  describe "claims#show request" do
    before { create(:policy_configuration, :additional_payments, current_academic_year: AcademicYear.new(2022)) }

    context "when a claim is already in progress" do
      let(:in_progress_claim) { Claim.by_policy(EarlyCareerPayments).order(:created_at).last }

      before { start_claim(EarlyCareerPayments.routing_name) }

      context "when the user has not completed the journey in the correct slug sequence" do
        it "redirects to the correct page in the sequence" do
          get claim_path(EarlyCareerPayments.routing_name, "landing-page")

          expect(response.body).to include(I18n.t("early_career_payments.landing_page"))
        end
      end

      context "when the user has completed the journey in the correct slug sequence" do
        before { set_slug_sequence_in_session(in_progress_claim, "teaching-subject-now") }

        it "renders the eligible-itt-subject in the sequence" do
          get claim_path(EarlyCareerPayments.routing_name, "teaching-subject-now")

          expect(response).to redirect_to(claim_path(EarlyCareerPayments.routing_name, "eligible-itt-subject"))
        end
      end

      context "when the user has completed the journey in the correct slug sequence" do
        before { set_slug_sequence_in_session(in_progress_claim, "postcode-search") }
        let(:address_line_1) { "1 Test Road" }
        let(:postcode) { "SO16 9FX" }

        before do
          allow(controller).to receive(:invalid_postcode?).and_return(false)
        end

        it "renders the requested page in the sequence" do
          get claim_path(EarlyCareerPayments.routing_name, "postcode-search", claim: {postcode: postcode, address_line_1: address_line_1})

          expect(response).to redirect_to(claim_path(EarlyCareerPayments.routing_name, "select-home-address", {"claim[postcode]": postcode, "claim[address_line_1]": address_line_1}))
        end
      end

      context "when the user is on the select-home-address slug and postcode is not present" do
        before do
          set_slug_sequence_in_session(in_progress_claim, "select-home-address")
        end

        it "clears the session variables and redirects to the postcode-search page" do
          get claim_path(EarlyCareerPayments.routing_name, "select-home-address")

          expect(session[:claim_postcode]).to be_nil
          expect(session[:claim_address_line_1]).to be_nil
          expect(response).to redirect_to(claim_path(EarlyCareerPayments.routing_name, "postcode-search"))
        end
      end

      context "when params[:slug] is select-home-address" do
        let!(:claim) { build(:claim, :submittable, postcode: "SO16 9FX") }
        let(:postcode) { "SO16 9FX" }
        let(:address_line_1) { "1 Test Road" }
        let(:claim_params) { {postcode: postcode, address_line_1: address_line_1} }

        before do
          stub_search_places_index(claim: claim)
          stub_search_places_show(claim: claim)
          set_slug_sequence_in_session(in_progress_claim, "select-home-address")
        end

        it "sets session variables and redirects correctly when address data is present" do
          expect(session[:claim_postcode]).to be_nil
          expect(session[:claim_address_line_1]).to be_nil
          expect(OrdnanceSurvey.configuration.client.base_url).to eq("https://api.os.uk")

          get claim_path(EarlyCareerPayments.routing_name, "select-home-address", claim: claim_params)

          expect(session[:claim_postcode]).to eq(postcode)
          expect(session[:claim_address_line_1]).to eq(address_line_1)
          expect(OrdnanceSurvey.configuration.client.base_url).to eq("https://api.os.uk")
          expect(response).to redirect_to(claim_path(EarlyCareerPayments.routing_name, "no-address-found"))
        end
      end

      # For early career payments
      context "when params[:slug] is 'current-school' and current_claim.logged_in_with_tid?" do
        let(:eligibility) { build(:early_career_payments_eligibility) }
        let(:claim) do
          create(:claim, policy: EarlyCareerPayments, logged_in_with_tid: true, teacher_reference_number: "1886094", date_of_birth: "1993-07-25")
        end

        let!(:current_claim) { CurrentClaim.new(claims: [claim]) }

        before do
          allow_any_instance_of(PartOfClaimJourney).to receive(:current_claim).and_return(current_claim)

          stub_dqt_request(current_claim.teacher_reference_number, current_claim.date_of_birth)

          set_slug_sequence_in_session(in_progress_claim, "nqt-in-academic-year-after-itt")
        end

        it "update the claim attributes from dqt api" do
          get claim_path(EarlyCareerPayments.routing_name, "nqt-in-academic-year-after-itt")

          expect(response.status).to eq(200)
          expect(current_claim.teacher_reference_number).to eq("1886094")
          expect(current_claim.logged_in_with_tid).to eq(true)
          expect(current_claim.eligibility.qualification).to eq("postgraduate_itt")
          expect(current_claim.eligibility.eligible_itt_subject).to eq("mathematics")
          expect(current_claim.eligibility.itt_academic_year).to eq(AcademicYear.new(2020))
        end
      end

      # For levelling up premium payments
      context "when params[:slug] is 'current-school' and current_claim.logged_in_with_tid?" do
        let(:eligibility) { build(:levelling_up_premium_payments_eligibility) }
        let(:claim) do
          create(:claim, policy: LevellingUpPremiumPayments, logged_in_with_tid: true, teacher_reference_number: "1886094", date_of_birth: "1993-07-25")
        end

        let!(:current_claim) { CurrentClaim.new(claims: [claim]) }

        before do
          allow_any_instance_of(PartOfClaimJourney).to receive(:current_claim).and_return(current_claim)

          stub_dqt_request(current_claim.teacher_reference_number, current_claim.date_of_birth)

          set_slug_sequence_in_session(in_progress_claim, "nqt-in-academic-year-after-itt")
        end

        it "update the claim attributes from dqt api" do
          get claim_path(LevellingUpPremiumPayments.routing_name, "nqt-in-academic-year-after-itt")

          expect(response.status).to eq(200)
          expect(current_claim.teacher_reference_number).to eq("1886094")
          expect(current_claim.logged_in_with_tid).to eq(true)
          expect(current_claim.eligibility.qualification).to eq("postgraduate_itt")
          expect(current_claim.eligibility.eligible_itt_subject).to eq("mathematics")
          expect(current_claim.eligibility.itt_academic_year).to eq(AcademicYear.new(2020))
        end
      end
    end
  end
end
