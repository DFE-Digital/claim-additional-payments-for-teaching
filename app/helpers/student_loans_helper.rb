module StudentLoansHelper
  # Returns the question for the claim-school page in the Student Loans journey.
  #
  # Accepts an optional named parameter `additional_school` that, if set to
  # `true`, will rephrase the question so it applies to a user searching for an
  # additional school.
  def claim_school_question(additional_school: false)
    if additional_school
      I18n.t("student_loans.questions.additional_school", financial_year: StudentLoans.current_financial_year)
    else
      I18n.t("student_loans.questions.claim_school", financial_year: StudentLoans.current_financial_year)
    end
  end
end
