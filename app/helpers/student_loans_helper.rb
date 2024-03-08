module StudentLoansHelper
  include ActionView::Helpers::TranslationHelper

  # Returns the question for the claim-school page in the Student Loans journey.
  #
  # Accepts an optional named parameter `additional_school` that, if set to
  # `true`, will rephrase the question so it applies to a user searching for an
  # additional school.
  def claim_school_question(additional_school: false)
    if additional_school
      translate("student_loans.questions.additional_school", financial_year: Policies::StudentLoans.current_financial_year)
    else
      translate("student_loans.questions.claim_school", financial_year: Policies::StudentLoans.current_financial_year)
    end
  end

  # Returns the question for the subjects-taugh page in the Student Loans
  # journey.
  #
  # Accepts a `school_name` named parameter that is the school that the claimant
  # was teaching at during the financial year.
  def subjects_taught_question(school_name:)
    translate("student_loans.questions.subjects_taught", school: school_name, financial_year: Policies::StudentLoans.current_financial_year)
  end

  # Returns the question for the leadership-position question in the Student
  # Loans journey.
  def leadership_position_question
    translate("student_loans.questions.leadership_position", financial_year: Policies::StudentLoans.current_financial_year)
  end

  # Returns the question for the mostly-performed-leadership-duties question in
  # the Student  Loans journey.
  def mostly_performed_leadership_duties_question
    translate("student_loans.questions.mostly_performed_leadership_duties", financial_year: Policies::StudentLoans.current_financial_year)
  end

  # Returns the question for the student-loan-amount question in the Student
  # Loans journey.
  def student_loan_amount_question
    translate("student_loans.questions.student_loan_amount", financial_year: Policies::StudentLoans.current_financial_year(:short))
  end
end
