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

  def qualification_details_before_show
    redirect_to_next_slug if no_dqt_data?
  end

  def address_before_show
    set_backlink_override(slug: "postcode-search") if no_postcode?
  end

  def select_home_address_before_show
    set_backlink_override(slug: "postcode-search")
  end

  def personal_bank_account_before_update
    inject_hmrc_validation_attempt_count_into_the_form
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

  def personal_bank_account_after_form_save_failure
    increment_hmrc_validation_attempt_count if hmrc_api_validation_attempted?
    render_template_for_current_slug
  end

  def postcode_search_after_form_save_failure
    lookup_failed_error = @form.errors.messages_for(:base).first
    if lookup_failed_error
      flash[:notice] = lookup_failed_error
      redirect_to_slug("address")
    else
      render_template_for_current_slug
    end
  end

  def check_your_email_after_form_save_success
    @email_resent = true
    render("check_your_email")
  end

  def check_your_answers_after_form_save_success
    create_and_save_claim_form
  end

  def employee_email_after_form_save_failure
    session[:slugs].delete("employee-email")
    render_template_for_current_slug
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

  def no_dqt_data?
    journey_session.answers.has_no_dqt_data_for_claim?
  end

  def no_postcode?
    !journey_session.answers.postcode
  end

  def retrieve_student_loan_details
    journey::AnswersStudentLoansDetailsUpdater.call(journey_session)
  end

  def hmrc_api_validation_attempted?
    @form&.hmrc_api_validation_attempted?
  end

  def inject_hmrc_validation_attempt_count_into_the_form
    params[:claim][:hmrc_validation_attempt_count] = current_hmrc_validation_attempt_count
  end

  def increment_hmrc_validation_attempt_count
    journey_session.answers.hmrc_validation_attempt_count = current_hmrc_validation_attempt_count + 1
    journey_session.save!
  end

  def current_hmrc_validation_attempt_count
    journey_session.answers.hmrc_validation_attempt_count || 0
  end

  def on_tid_route?
    journey_session.answers.logged_in_with_tid? && journey_session.answers.all_personal_details_same_as_tid?
  end
end
