require "rails_helper"

RSpec.describe "Claims", type: :request do
  describe "claims#new request" do
    before { create(:journey_configuration, :student_loans) }

    context "the user has not already started a claim" do
      it "renders the first page in the sequence" do
        get new_claim_path(Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME)
        follow_redirect!
        expect(response.body).to include("Use DfE Identity to sign in")
      end
    end

    it "redirects to the existing claim interruption page if another claim for the same policy is already in progress" do
      start_student_loans_claim
      get new_claim_path(Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME)

      expect(response).to redirect_to(existing_session_path(Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME))
    end

    context "switching claim policies" do
      before { create(:journey_configuration, :additional_payments) }

      it "redirects to the existing claim interruption page if a claim for another policy is already in progress" do
        start_student_loans_claim
        get new_claim_path(Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME)

        expect(response).to redirect_to(existing_session_path(Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME))
      end
    end
  end

  describe "claims#create request" do
    def check_claims_created
      expect { start_claim(@journey_configuration.journey::ROUTING_NAME) }.to change { @journey_configuration.journey::Session.count }.by(1)
    end

    def check_claims_eligibility_created
      journey_session = @journey_configuration.journey::Session.last

      expect(journey_session.answers.academic_year).to eq(@journey_configuration.current_academic_year)
    end

    def check_slug_redirection
      expect(response).to redirect_to(claim_path(@journey_configuration.journey::ROUTING_NAME, @journey_configuration.journey.slug_sequence::SLUGS.first))
    end

    context "student loans claim" do
      it "created for the current academic year and redirects to the next question in the sequence" do
        @journey_configuration = create(:journey_configuration, :student_loans)

        check_claims_created
        check_claims_eligibility_created
        check_slug_redirection
      end
    end

    context "ecp and targeted_retention_incentive combined claim" do
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
      let(:journey_session) { Journeys::TeacherStudentLoanReimbursement::Session.order(:created_at).last }

      before { start_student_loans_claim }

      context "when the user has not completed the journey in the correct slug sequence" do
        it "redirects to the correct page in the sequence" do
          get claim_path(Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME, "sign-in-or-continue")
          expect(response.body).to include("Use DfE Identity to sign in")
          patch claim_path(Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME, "sign-in-or-continue")

          get claim_path(Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME, "claim-school")
          expect(response).to redirect_to(claim_path(Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME, "qts-year"))
        end
      end

      context "when the user has completed the journey in the correct slug sequence" do
        before { set_slug_sequence_in_session(journey_session, "claim-school") }

        it "renders the requested page in the sequence" do
          get claim_path(Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME, "claim-school")
          expect(response.body).to include("Which school were you employed to teach at")
        end

        context "when searching for a school on the claim-school page" do
          let!(:school_1) { create(:school) }
          let!(:school_2) { create(:school) }

          it "searches for schools using the search term" do
            get claim_path(Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME, "claim-school"), params: {school_search: school_1.name}

            # Issues with e.g. "O&#39;Kon and Sons School" matching "O'Kon and Sons School", quickfix escape html
            expect(response.body).to include CGI.escapeHTML(school_1.name)
            expect(response.body).not_to include CGI.escapeHTML(school_2.name)

            expect(response.body).to include "Continue"
          end

          it "only returns results if the search term is more than two characters" do
            get claim_path(Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME, "claim-school"), params: {school_search: "ab"}

            expect(response.body).to include("There is a problem")
            expect(response.body).to include("Enter a school or postcode")
            expect(response.body).not_to include(school_1.name)
          end

          it "shows an appropriate message when there are no search results" do
            get claim_path(Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME, "claim-school"), params: {school_search: "crocodile"}

            expect(response.body).to include("No results match that search term")
          end
        end
      end
    end

    context "when a claim hasn’t been started yet" do
      it "redirects to the start page indicated by the routing" do
        get claim_path(Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME, "qts-year")
        expect(response).to redirect_to(Journeys::TeacherStudentLoanReimbursement.start_page_url)
      end
    end
  end

  describe "the claims ineligible page" do
    before { create(:journey_configuration, :student_loans) }

    context "when a claim is already in progress" do
      before { start_student_loans_claim }

      it "renders a static ineligibility page" do
        journey_session = Journeys::TeacherStudentLoanReimbursement::Session.order(:created_at).last
        journey_session.answers.assign_attributes(employment_status: "no_school")
        journey_session.save!

        get claim_path(Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME, "ineligible")

        expect(response.body).to include("You’re not eligible")
        expect(response.body).to include("You can only get this payment if you’re still employed to teach at a state-funded secondary school.")
      end
    end

    context "when a claim hasn’t been started yet" do
      it "redirects to the start page indicated by the routing" do
        get claim_path(Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME, "ineligible")
        expect(response).to redirect_to(Journeys::TeacherStudentLoanReimbursement.start_page_url)
      end
    end
  end

  describe "claims#update request" do
    before { create(:journey_configuration, :student_loans) }

    context "when a claim is already in progress" do
      let(:journey_session) do
        Journeys::TeacherStudentLoanReimbursement::Session.order(:created_at).last
      end

      before {
        start_student_loans_claim
        set_slug_sequence_in_session(journey_session, "qts-year")
      }

      it "updates the claim with the submitted form data" do
        put claim_path(Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME, "qts-year"), params: {claim: {qts_award_year: "on_or_after_cut_off_date"}}

        expect(response).to redirect_to(claim_path(Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME, "claim-school"))
        expect(journey_session.reload.answers.qts_award_year).to eq "on_or_after_cut_off_date"
      end

      it "makes sure validations appropriate to the context are run" do
        put claim_path(Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME, "qts-year"), params: {claim: {qts_award_year: nil}}
        expect(response.body).to include("Select when you completed your initial teacher training")
      end

      context "when initiating the request from personal-details" do
        let(:params) do
          {
            claim: {
              first_name: "John",
              surname: "Doe",
              "date_of_birth(3i)": "1", "date_of_birth(2i)": "1", "date_of_birth(1i)": "1990",
              national_insurance_number: "QQ123456C"
            }
          }
        end
        let(:request) { put claim_path(Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME, "personal-details"), params: }

        before do
          set_slug_sequence_in_session(journey_session, "personal-details")
        end

        context "when there is no student loan data for the claimant" do
          it "does not update the student loan details" do
            expect { request }.not_to change { journey_session.reload }
          end
        end

        context "when there is student loan data showing the claimant has a student loan" do
          before { create(:student_loans_data, nino: "QQ123456C", date_of_birth: Date.new(1990, 1, 1)) }

          it "updates the student loan details" do
            expect { request }.to change { journey_session.reload.answers.has_student_loan }.to(true)
              .and change { journey_session.reload.answers.student_loan_plan }.to("plan_1")
          end
        end

        context "when there is student loan data showing the claimant does not have student loan" do
          before { create(:student_loans_data, :no_student_loan, nino: "QQ123456C", date_of_birth: Date.new(1990, 1, 1)) }

          it "updates the student loan details" do
            expect { request }.to change { journey_session.reload.answers.has_student_loan }.to(false)
              .and change { journey_session.reload.answers.student_loan_plan }.to("not_applicable")
          end
        end
      end

      context "when initiating the request from information-provided" do
        let(:request) { put claim_path(Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME, "information-provided"), params: {} }

        before do
          if tid_journey?
            journey_session.answers.assign_attributes(logged_in_with_tid: true)
            journey_session.save!
          end
          set_slug_sequence_in_session(journey_session, "information-provided")
        end

        context "within the non-TID journey" do
          let(:tid_journey?) { false }

          it "does not update the student loan details" do
            expect { request }.to not_change { journey_session.reload.answers.has_student_loan }
              .and not_change { journey_session.reload.answers.student_loan_plan }
          end
        end

        context "within the TID journey" do
          let(:tid_journey?) { true }

          context "when the claim has all valid personal details" do
            before do
              journey_session.answers.assign_attributes(
                first_name: "John",
                surname: "Doe",
                date_of_birth: "1/1/1990",
                national_insurance_number: "QQ123456C",
                teacher_id_user_info: {
                  "given_name" => "John",
                  "family_name" => "Doe",
                  "birthdate" => "1990-01-01",
                  "ni_number" => "QQ123456C"
                }
              )

              journey_session.save!
            end

            context "when there is no student loan data for the claimant" do
              it "does not update the student loan details" do
                expect { request }.not_to change { journey_session.reload }
              end
            end

            context "when there is student loan data showing the claimant has a student loan" do
              before { create(:student_loans_data, nino: "QQ123456C", date_of_birth: Date.new(1990, 1, 1)) }

              it "updates the student loan details" do
                expect { request }.to change { journey_session.reload.answers.has_student_loan }.to(true)
                  .and change { journey_session.reload.answers.student_loan_plan }.to("plan_1")
              end
            end

            context "when there is student loan data showing the claimant does not have student loan" do
              before { create(:student_loans_data, :no_student_loan, nino: "QQ123456C", date_of_birth: Date.new(1990, 1, 1)) }

              it "updates the student loan details" do
                expect { request }.to change { journey_session.reload.answers.has_student_loan }.to(false)
                  .and change { journey_session.reload.answers.student_loan_plan }.to("not_applicable")
              end
            end
          end

          context "when the claim does not have all valid personal details" do
            before do
              journey_session.answers.assign_attributes(
                first_name: "John",
                surname: "Doe",
                date_of_birth: "1/1/1990",
                national_insurance_number: "QQ123456C",
                teacher_id_user_info: {
                  "given_name" => "Not John",
                  "family_name" => "Doe",
                  "birthdate" => "1990-01-01",
                  "ni_number" => "QQ123456C"
                }
              )

              journey_session.save!
            end

            it "does not update the student loan details" do
              expect { request }.to(
                not_change { journey_session.reload.answers.has_student_loan }.and(
                  not_change { journey_session.reload.answers.student_loan_plan }
                )
              )
            end
          end
        end
      end

      context "when the user has not completed the journey in the correct slug sequence" do
        it "redirects to the start of the journey" do
          put claim_path(Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME, "student-loan-amount"), params: {claim: {has_student_loan: true}}
          expect(response).to redirect_to(claim_path(Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME, "qts-year"))
        end
      end

      context "when the user has completed the journey in the correct slug sequence" do
        before { set_slug_sequence_in_session(journey_session, "provide-mobile-number") }

        it "resets dependent claim attributes when appropriate" do
          journey_session.answers.assign_attributes(provide_mobile_number: false, mobile_number: nil)
          journey_session.save!
          put claim_path(Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME, "provide-mobile-number"), params: {claim: {provide_mobile_number: true}}

          expect(response).to redirect_to(claim_path(Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME, "mobile-number"))
          expect(journey_session.reload.answers.student_loan_plan).to be_nil
        end
      end

      it "resets depenent eligibility attributes when appropriate" do
        journey_session.answers.assign_attributes(
          had_leadership_position: true,
          mostly_performed_leadership_duties: false
        )
        journey_session.save!
        set_slug_sequence_in_session(journey_session, "leadership-position")
        put claim_path(Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME, "leadership-position"), params: {claim: {had_leadership_position: false}}

        expect(response).to redirect_to(claim_path(Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME, "eligibility-confirmed"))
        expect(
          journey_session.reload.answers.mostly_performed_leadership_duties
        ).to be_nil
      end

      context "having searched for a school but not selected a school from the results on the claim-school page" do
        let!(:school) { create(:school) }

        before { set_slug_sequence_in_session(journey_session, "claim-school") }

        it "re-renders the school search results with an error message" do
          put claim_path(Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME, "claim-school"), params: {school_search: school.name, claim: {claim_school_id: ""}}

          expect(response).to be_successful
          expect(response.body).to include("There is a problem")
          expect(response.body).to include("Select a school from the list")
          expect(response.body).to include(CGI.escapeHTML(school.name)) # eg. apostrophe characters become HTML entities
        end
      end

      context "when the update makes the claim ineligible" do
        let(:ineligible_school) { create(:school, :student_loans_ineligible) }

        it "redirects to the “ineligible” page" do
          set_slug_sequence_in_session(journey_session, "claim-school")
          put claim_path(Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME, "claim-school"), params: {claim: {claim_school_id: ineligible_school.to_param}}

          expect(response).to redirect_to(claim_path(Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME, "ineligible"))
        end
      end
    end

    context "when a claim hasn’t been started yet" do
      it "redirects to the start page indicated by the routing" do
        put claim_path(Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME, "qts-year"), params: {claim: {qts_award_year: "on_or_after_cut_off_date"}}
        expect(response).to redirect_to(Journeys::TeacherStudentLoanReimbursement.start_page_url)
      end
    end
  end

  # 2022/2023 onwards /additional-payments covers ECP and Targeted Retention Incentive claims
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
