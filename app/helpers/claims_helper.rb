module ClaimsHelper
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
      [t("tslr.questions.current_school"), claim.current_school_name, "still-teaching"],
      [t("tslr.questions.subjects_taught"), subject_list(claim.subjects_taught), "subjects-taught"],
      [t("tslr.questions.mostly_teaching_eligible_subjects", subjects: subject_list(claim.subjects_taught)), (claim.mostly_teaching_eligible_subjects? ? "Yes" : "No"), "mostly-teaching-eligible-subjects"],
      [t("tslr.questions.student_loan_amount", claim_school_name: claim.claim_school_name), number_to_currency(claim.student_loan_repayment_amount), "student-loan-amount"],
    ]
  end

  def identity_answers(claim)
    [
      [t("tslr.questions.full_name"), claim.full_name, "full-name"],
      [t("tslr.questions.address"), claim.address, "address"],
      [t("tslr.questions.date_of_birth"), l(claim.date_of_birth), "date-of-birth"],
      [t("tslr.questions.teacher_reference_number"), claim.teacher_reference_number, "teacher-reference-number"],
      [t("tslr.questions.national_insurance_number"), claim.national_insurance_number, "national-insurance-number"],
      [t("tslr.questions.email_address"), claim.email_address, "email-address"],
    ]
  end

  def student_loan_answers(claim)
    [[t("tslr.questions.has_student_loan"), (claim.has_student_loan ? "Yes" : "No"), "student-loan"]].tap do |answers|
      answers << [t("tslr.questions.student_loan_country"), claim.student_loan_country.humanize, "student-loan-country"] if claim.student_loan_country.present?
      answers << [t("tslr.questions.student_loan_how_many_courses"), claim.student_loan_courses.humanize, "student-loan-how-many-courses"] if claim.student_loan_courses.present?
      answers << [t("tslr.questions.student_loan_start_date.#{claim.student_loan_courses}"), t("tslr.answers.student_loan_start_date.#{claim.student_loan_courses}.#{claim.student_loan_start_date}"), "student-loan-start-date"] if claim.student_loan_courses.present?
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
    translated_subjects = subjects.map { |subject| I18n.t("tslr.questions.eligible_subjects.#{subject}") }
    translated_subjects.sort.to_sentence(
      last_word_connector: connector,
      two_words_connector: connector
    )
  end

  private

  def academic_years(year_range)
    start_year, end_year = year_range.split("_")

    "September 1 #{start_year} - August 31 #{end_year}"
  end
end
