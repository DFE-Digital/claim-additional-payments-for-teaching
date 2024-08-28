module ClaimSubmission
  extend ActiveSupport::Concern

  def create_and_save_claim_form
    @form = journey::ClaimSubmissionForm.new(journey_session: journey_session)

    if @form.save
      session[:submitted_claim_id] = @form.claim.id
      clear_claim_session
      redirect_to claim_confirmation_path
    else
      render "claims/check_your_answers"
    end
  end
end
