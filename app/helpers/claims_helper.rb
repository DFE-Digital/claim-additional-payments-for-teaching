module ClaimsHelper
  def tslr_guidance_url
    "https://www.gov.uk/guidance/teachers-student-loan-reimbursement-guidance-for-teachers-and-schools"
  end

  def claim_timeout_in_minutes
    ApplicationController::CLAIM_TIMEOUT_LENGTH_IN_MINUTES
  end

  def claim_timeout_warning_in_minutes
    ApplicationController::CLAIM_TIMEOUT_WARNING_LENGTH_IN_MINUTES
  end

  def eligibility_answers(eligibility)
    [].tap do |a|
      a << [t("student_loans.questions.qts_award_year"), academic_years(eligibility.qts_award_year), "qts-year"]
      a << [t("student_loans.questions.claim_school"), eligibility.claim_school_name, "claim-school"]
      a << [t("questions.current_school"), eligibility.current_school_name, "still-teaching"]
      a << [t("student_loans.questions.subjects_taught"), subject_list(eligibility.subjects_taught), "subjects-taught"]
      a << [t("student_loans.questions.leadership_position"), (eligibility.had_leadership_position? ? "Yes" : "No"), "leadership-position"]
      a << [t("student_loans.questions.mostly_performed_leadership_duties"), (eligibility.mostly_performed_leadership_duties? ? "Yes" : "No"), "mostly-performed-leadership-duties"] if eligibility.had_leadership_position?
      a << [t("student_loans.questions.student_loan_amount", claim_school_name: eligibility.claim_school_name), number_to_currency(eligibility.student_loan_repayment_amount), "student-loan-amount"]
    end
  end

  def identity_answers(claim)
    [].tap do |a|
      a << [t("questions.address"), claim.address, "address"] unless claim.address_verified?
      a << [t("questions.payroll_gender"), t("answers.payroll_gender.#{claim.payroll_gender}"), "gender"] unless claim.payroll_gender_verified?
      a << [t("questions.teacher_reference_number"), claim.teacher_reference_number, "teacher-reference-number"]
      a << [t("questions.national_insurance_number"), claim.national_insurance_number, "national-insurance-number"]
      a << [t("questions.email_address"), claim.email_address, "email-address"]
    end
  end

  def student_loan_answers(claim)
    [[t("questions.has_student_loan"), (claim.has_student_loan ? "Yes" : "No"), "student-loan"]].tap do |answers|
      answers << [t("student_loans.questions.student_loan_country"), claim.student_loan_country.humanize, "student-loan-country"] if claim.student_loan_country.present?
      answers << [t("questions.student_loan_how_many_courses"), claim.student_loan_courses.humanize, "student-loan-how-many-courses"] if claim.student_loan_courses.present?
      answers << [t("questions.student_loan_start_date.#{claim.student_loan_courses}"), t("answers.student_loan_start_date.#{claim.student_loan_courses}.#{claim.student_loan_start_date}"), "student-loan-start-date"] if claim.student_loan_courses.present?
    end
  end

  def payment_answers(claim)
    [
      ["Bank sort code", claim.bank_sort_code, "bank-details"],
      ["Bank account number", claim.bank_account_number, "bank-details"],
    ]
  end

  def subject_list(subjects)
    connector = " and "
    translated_subjects = subjects.map { |subject| I18n.t("student_loans.questions.eligible_subjects.#{subject}") }
    translated_subjects.sort.to_sentence(
      last_word_connector: connector,
      two_words_connector: connector
    )
  end

  def academic_years(year_range)
    return unless year_range.present?

    start_year, end_year = year_range.split("_")
    start_date = Date.new(start_year.to_i, 9, 1)
    end_date = Date.new(end_year.to_i, 8, 31)
    "#{l(start_date)} to #{l(end_date)}"
  end
end
