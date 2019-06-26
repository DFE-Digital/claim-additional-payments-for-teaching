module ClaimsHelper
  def options_for_qts_award_year
    TslrClaim::VALID_QTS_YEARS.map { |year_range| [academic_years(year_range), year_range] }
  end

  def tslr_guidance_url
    "https://www.gov.uk/guidance/teachers-student-loan-reimbursement-guidance-for-teachers-and-schools"
  end

  def claim_timeout_in_minutes
    ClaimsController::TIMEOUT_LENGTH_IN_MINUTES
  end

  def claim_timeout_warning_in_minutes
    ClaimsController::TIMEOUT_WARNING_LENGTH_IN_MINUTES
  end

  def claim_answers(claim)
    [
      [t("tslr.questions.qts_award_year"), academic_years(claim.qts_award_year), "qts-year"],
      [t("tslr.questions.claim_school"), claim.claim_school_name, "claim-school"],
      [t("tslr.questions.current_school"), claim.current_school_name, "current-school"],
      [t("tslr.questions.subjects_taught"), subject_list(claim.eligible_subjects, "and"), "subjects-taught"],
      [t("tslr.questions.mostly_teaching_eligible_subjects", subjects: subject_list(claim.eligible_subjects, "or")), (claim.mostly_teaching_eligible_subjects? ? "Yes" : "No"), "mostly-teaching-eligible-subjects"],
      [t("tslr.questions.student_loan_amount", claim_school_name: claim.claim_school_name), number_to_currency(claim.student_loan_repayment_amount), "student-loan-amount"],
    ]
  end

  def identity_answers(claim)
    [
      ["Full name", claim.full_name, "full-name"],
      ["Address", claim.address, "address"],
      ["Date of birth", l(claim.date_of_birth), "date-of-birth"],
      ["Teacher reference number", claim.teacher_reference_number, "teacher-reference-number"],
      ["National Insurance number", claim.national_insurance_number, "national-insurance-number"],
      ["Email address", claim.email_address, "email-address"],
      ["Account number", claim.bank_account_number, "bank-details"],
      ["Sort code", claim.bank_sort_code, "bank-details"],
    ]
  end

  def subject_list(subjects, connector = "or")
    connector = " #{connector} "
    translated_subjects = subjects.map { |subject| I18n.t("tslr.questions.eligible_subjects.#{subject}") }
    translated_subjects.to_sentence(
      last_word_connector: connector,
      two_words_connector: connector
    )
  end

  private

  def academic_years(year_range)
    start_year, end_year = year_range.split("-")

    "September 1 #{start_year} - August 31 #{end_year}"
  end
end
