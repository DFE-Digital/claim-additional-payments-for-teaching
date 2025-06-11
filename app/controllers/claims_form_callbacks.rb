module ClaimsFormCallbacks
  def check_your_answers_after_form_save_success
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
