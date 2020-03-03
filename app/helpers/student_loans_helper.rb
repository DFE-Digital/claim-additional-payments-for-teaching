module StudentLoansHelper
  def claim_school_question(searching_for_additional_school)
    searching_for_additional_school ? t("student_loans.questions.additional_school") : t("student_loans.questions.claim_school")
  end
end
