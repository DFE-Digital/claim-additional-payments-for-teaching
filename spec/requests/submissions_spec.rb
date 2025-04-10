require "rails_helper"

RSpec.describe "Submissions", type: :request do
  let(:journey_session) do
    Journeys::TeacherStudentLoanReimbursement::Session.order(:created_at).last
  end

  let(:answers) { journey_session.answers }

  before { create(:journey_configuration, :student_loans) }

  describe "#create" do
    context "with a submittable claim" do
      before do
        start_student_loans_claim
        # Make the claim submittable
        journey_session.update!(
          answers: attributes_for(:student_loans_answers, :submittable)
        )

        stub_qualified_teaching_statuses_show(
          trn: answers.teacher_reference_number,
          params: {
            birthdate: answers.date_of_birth&.to_s,
            nino: answers.national_insurance_number
          }
        )
      end

      it "submits the claim, sends a confirmation email and redirects to the confirmation page and clears the session data" do
        perform_enqueued_jobs { post claim_submission_path(Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME) }
        expect(response).to redirect_to(claim_confirmation_path(Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME))

        submitted_claim = Claim.by_policy(Policies::StudentLoans).order(:created_at).last
        expect(submitted_claim.submitted_at).to be_present

        email = ActionMailer::Base.deliveries.first
        expect(email.personalisation[:ref_number]).to eql(submitted_claim.reference)

        expect(session[:slugs]).to be_nil
        expect(session[:submitted_claim_id]).to eq(submitted_claim.id)
      end

      # TODO: one of these specs should be here, should be in features.
      #
      # Instead of refactoring everything as part of an already large PR, I've
      # just added another spec here.
      #
      # Really all these specs should be in features and should test the right
      # thing, eg,the above spec tests that a request has been made rather than
      # the immediate side effect of the job being enqueued.
      #
      # This spec at least tests the right thing even if it's still in the
      # wrong place.
      it "enqueues ClaimVerifierJob" do
        expect { post claim_submission_path(Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME) }.to(
          have_enqueued_job(ClaimVerifierJob)
        )
      end
    end

    context "with an unsubmittable claim" do
      before :each do
        start_student_loans_claim
        # Make the claim _almost_ submittable
        journey_session.answers.assign_attributes(
          attributes_for(:student_loans_answers, :submittable, email_address: nil)
        )

        journey_session.save!

        perform_enqueued_jobs { post claim_submission_path(Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME) }
      end

      it "doesn't submit the claim and renders the check-your-answers page with the reasons why" do
        expect(journey_session.submitted?).to eq false
        expect(ActionMailer::Base.deliveries).to be_empty
        expect(response.body).to include("Check your answers before sending your application")
        expect(response.body).to include("Enter an email address")
      end
    end

    it "redirects to the start page if there is no claim actually in progress" do
      post claim_submission_path(Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME)
      expect(response).to redirect_to(Journeys::TeacherStudentLoanReimbursement.start_page_url)
    end
  end

  describe "#show" do
    before do
      start_student_loans_claim
    end

    context "when the user has followed the slug sequence" do
      before do
        set_session_data(submitted_claim_id: create(:claim, :submittable).id)
      end

      it "renders the claim confirmation screen, including identity checking content" do
        get claim_confirmation_path(Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME)

        expect(response.body).to include("Claim submitted")
        expect(response.body).to include("Your application will be reviewed by the Department for Education")
      end
    end

    context "when the user has not followed the slug sequence" do
      it "redirect to the start page" do
        get claim_confirmation_path(Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME)
        expect(response).to redirect_to(Journeys::TeacherStudentLoanReimbursement.start_page_url)
      end
    end

    context "when the claim with submitted_claim_id in the session is a policy that is not for this journey" do
      before do
        create(:journey_configuration, :additional_payments)
        set_session_data(submitted_claim_id: create(:claim, :submitted).id)
      end

      it "redirects to the start page of the journey in the url path ignoring the submitted_claim_id" do
        get claim_confirmation_path(Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME)
        expect(response).to redirect_to(Journeys::AdditionalPaymentsForTeaching.start_page_url)
      end
    end
  end
end
