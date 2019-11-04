require "rails_helper"

RSpec.describe "Submissions", type: :request do
  describe "#create" do
    let(:in_progress_claim) { Claim.order(:created_at).last }

    context "with a submittable claim" do
      before do
        start_claim
        # Make the claim submittable
        in_progress_claim.update!(attributes_for(:claim, :submittable))
        in_progress_claim.eligibility.update!(attributes_for(:student_loans_eligibility, :eligible))

        perform_enqueued_jobs { post claim_submission_path(StudentLoans.routing_name) }
      end

      it "submits the claim, sends a confirmation email and redirects to the confirmation page" do
        expect(response).to redirect_to(claim_confirmation_path(StudentLoans.routing_name))

        expect(in_progress_claim.reload.submitted_at).to be_present

        email = ActionMailer::Base.deliveries.first
        expect(email.to).to eql([in_progress_claim.email_address])
        expect(email.subject).to eql("Your claim was received")
        expect(email.body).to include("Your unique reference is #{in_progress_claim.reference}.")
      end
    end

    context "with an unsubmittable claim" do
      before :each do
        start_claim
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

    it "redirects to the start page if a claim isn't in progress" do
      post claim_submission_path(StudentLoans.routing_name)
      expect(response).to redirect_to(StudentLoans.start_page_url)
    end
  end

  describe "#show" do
    before { start_claim }

    context "with a submitted claim" do
      it "renders the claim confirmation screen and clears the session" do
        get claim_confirmation_path(StudentLoans.routing_name)

        expect(response.body).to include("Claim submitted")
        expect(session[:claim_id]).to be_nil
      end
    end
  end
end
