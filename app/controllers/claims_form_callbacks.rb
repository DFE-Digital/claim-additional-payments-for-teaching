module ClaimsFormCallbacks
  def teaching_subject_now_before_show
    redirect_to_slug("eligible-itt-subject") if no_eligible_itt_subject?
  end

  def check_your_email_after_form_save_success
    @email_resent = true
    render("check_your_email")
  end

  def check_your_answers_after_form_save_success
    create_and_save_claim_form
  end

  private

  def no_eligible_itt_subject?
    !journey_session.answers.eligible_itt_subject
  end
end
