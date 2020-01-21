require "rails_helper"

RSpec.describe "Submissions", type: :request do
  let(:in_progress_claim) { Claim.last }

  describe "#create" do
    context "with a submittable student loans claim" do
      before do
        @dataset_post_stub = stub_geckoboard_dataset_update

        start_student_loans_claim
        # Make the claim submittable
        in_progress_claim.update!(attributes_for(:claim, :submittable))
        in_progress_claim.eligibility.update!(attributes_for(:student_loans_eligibility, :eligible))

        perform_enqueued_jobs { post claim_submission_path(StudentLoans.routing_name) }
      end

      it "submits the claim, sends a confirmation email and redirects to the confirmation page" do
        expect(response).to redirect_to(claim_confirmation_path(StudentLoans.routing_name))

        expect(in_progress_claim.reload.submitted_at).to be_present

        follow_redirect!

        expect(response.body).to include("What did you think of this service?")
        expect(response.body).to include(in_progress_claim.policy.done_page_url)

        email = ActionMailer::Base.deliveries.first
        expect(email.to).to eql([in_progress_claim.email_address])
        expect(email.subject).to match("been received")
        expect(email.body).to include("Your unique reference is #{in_progress_claim.reference}.")
      end

      it "sends the claim's details to the “submitted” dataset on Geckoboard" do
        expect(@dataset_post_stub.with { |request|
          request_body_matches_geckoboard_data_for_claims?(request, [in_progress_claim.reload])
        }).to have_been_requested
      end
    end

    context "with a submittable maths and physics claim" do
      before do
        start_maths_and_physics_claim
        # Make the claim submittable
        in_progress_claim.update!(attributes_for(:claim, :submittable))
        in_progress_claim.eligibility.update!(attributes_for(:maths_and_physics_eligibility, :eligible))

        post claim_submission_path(MathsAndPhysics.routing_name)
      end

      it "does not show a done page link" do
        expect(response).to redirect_to(claim_confirmation_path(MathsAndPhysics.routing_name))

        expect(in_progress_claim.reload.submitted_at).to be_present

        follow_redirect!

        expect(response.body).to_not include("What did you think of this service?")
      end
    end

    context "with an unsubmittable claim" do
      before :each do
        start_student_loans_claim
        # Make the claim _almost_ submittable
        in_progress_claim.update!(attributes_for(:claim, :submittable, email_address: nil))

        perform_enqueued_jobs { post claim_submission_path(StudentLoans.routing_name) }
      end

      it "doesn't submit the claim and renders the check-your-answers page with the reasons why" do
        expect(in_progress_claim.reload.submitted_at).to be_nil
        expect(ActionMailer::Base.deliveries).to be_empty
        expect(response.body).to include("Check your answers before sending your application")
        expect(response.body).to include("Enter an email address")
      end
    end

    it "redirects to the start page if there is no claim actually in progress" do
      post claim_submission_path(StudentLoans.routing_name)
      expect(response).to redirect_to(StudentLoans.start_page_url)
    end
  end

  describe "#show" do
    before do
      start_student_loans_claim
      in_progress_claim.update!(attributes_for(:claim, :submittable))
    end

    context "with a submitted claim that completed GOV.UK Verify" do
      it "renders the claim confirmation screen and clears the session" do
        get claim_confirmation_path(StudentLoans.routing_name)

        expect(response.body).to include("Claim submitted")
        expect(response.body).to include("check the details you provided in your application")
        expect(session[:claim_id]).to be_nil
      end
    end

    context "with a submitted claim that did not complete GOV.UK Verify" do
      it "renders the claim confirmation screen, including identity checking content, and clears the session" do
        in_progress_claim.update!(govuk_verify_fields: [])

        get claim_confirmation_path(StudentLoans.routing_name)

        expect(response.body).to include("Claim submitted")
        expect(response.body).to include("contact you at your school to confirm your identity")
        expect(session[:claim_id]).to be_nil
      end
    end
  end
end
