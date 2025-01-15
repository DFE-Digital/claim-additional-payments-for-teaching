module ClaimsFormCallbacks
  def current_school_before_show
    set_backlink_override_to_current_slug if on_school_search_results?
  end

  def claim_school_before_show
    set_backlink_override_to_current_slug if on_school_search_results?
  end

  def teaching_subject_now_before_show
    redirect_to_slug("eligible-itt-subject") if no_eligible_itt_subject?
  end

  def information_provided_before_update
    return unless journey.requires_student_loan_details?

    retrieve_student_loan_details if on_tid_route?
  end

  def personal_details_after_form_save_success
    return redirect_to_next_slug unless journey.requires_student_loan_details?

    retrieve_student_loan_details
    redirect_to_next_slug
  end

  def check_your_email_after_form_save_success
    @email_resent = true
    render("check_your_email")
  end

  def check_your_answers_after_form_save_success
    create_and_save_claim_form
  end

  private

  def set_backlink_override_to_current_slug
    set_backlink_override(slug: current_slug)
  end

  def set_backlink_override(slug:)
    @backlink_path = claim_path(current_journey_routing_name, slug) if page_sequence.in_sequence?(slug)
  end

  def on_school_search_results?
    params[:school_search]&.present?
  end

  def no_eligible_itt_subject?
    !journey_session.answers.eligible_itt_subject
  end

  def retrieve_student_loan_details
    journey::AnswersStudentLoansDetailsUpdater.call(journey_session)
  end

  def on_tid_route?
    journey_session.answers.logged_in_with_tid? && journey_session.answers.all_personal_details_same_as_tid?
  end
end
