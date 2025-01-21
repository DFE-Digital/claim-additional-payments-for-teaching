class InformationProvidedForm < Form
  def save
    if journey.requires_student_loan_details? && on_tid_route?
      retrieve_student_loan_details
    end

    true
  end

  private

  def on_tid_route?
    journey_session.answers.logged_in_with_tid? && journey_session.answers.all_personal_details_same_as_tid?
  end

  def retrieve_student_loan_details
    journey::AnswersStudentLoansDetailsUpdater.call(journey_session)
  end
end
