module ClaimsHelper
  def tslr_guidance_url
    "https://www.gov.uk/guidance/teachers-student-loan-reimbursement-guidance-for-teachers-and-schools"
  end

  def verified_fields(claim)
    fields = []
    fields << I18n.t("verified_fields.first_name") if claim.verified_fields.include?("first_name")
    fields << I18n.t("verified_fields.middle_name") if claim.verified_fields.include?("middle_name")
    fields << I18n.t("verified_fields.surname") if claim.verified_fields.include?("surname")
    fields << I18n.t("verified_fields.address") if claim.address_verified?
    fields << I18n.t("verified_fields.date_of_birth") if claim.verified_fields.include?("date_of_birth")
    fields << I18n.t("verified_fields.payroll_gender") if claim.payroll_gender_verified?
    fields.to_sentence
  end

  def eligibility_answers(eligibility)
    [].tap do |a|
      a << [t("student_loans.questions.qts_award_year"), I18n.t("student_loans.questions.qts_award_years.#{eligibility.qts_award_year}"), "qts-year"]
      a << [t("student_loans.questions.claim_school"), eligibility.claim_school_name, "claim-school"]
      a << [t("questions.current_school"), eligibility.current_school_name, "still-teaching"]
      a << [t("student_loans.questions.subjects_taught"), subject_list(eligibility.subjects_taught), "subjects-taught"]
      a << [t("student_loans.questions.leadership_position"), (eligibility.had_leadership_position? ? "Yes" : "No"), "leadership-position"]
      a << [t("student_loans.questions.mostly_performed_leadership_duties"), (eligibility.mostly_performed_leadership_duties? ? "Yes" : "No"), "mostly-performed-leadership-duties"] if eligibility.had_leadership_position?
    end
  end

  def verify_answers(claim)
    [].tap do |a|
      a << [I18n.t("verified_fields.first_name").capitalize, claim.first_name]
      a << [I18n.t("verified_fields.middle_name").capitalize, claim.middle_name] if claim.middle_name.present?
      a << [I18n.t("verified_fields.surname").capitalize, claim.surname]
      a << [I18n.t("verified_fields.address").capitalize, sanitize(claim.address("<br>").html_safe, tags: %w[br])] if claim.address_verified?
      a << [I18n.t("verified_fields.date_of_birth").capitalize, l(claim.date_of_birth)]
      a << [I18n.t("verified_fields.payroll_gender").capitalize, t("answers.payroll_gender.#{claim.payroll_gender}")] if claim.payroll_gender_verified?
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
    [].tap do |a|
      a << [t("questions.has_student_loan"), (claim.has_student_loan ? "Yes" : "No"), "student-loan"]
      a << [t("questions.student_loan_country"), claim.student_loan_country.titleize, "student-loan-country"] if claim.student_loan_country.present?
      a << [t("questions.student_loan_how_many_courses"), claim.student_loan_courses.humanize, "student-loan-how-many-courses"] if claim.student_loan_courses.present?
      a << [t("questions.student_loan_start_date.#{claim.student_loan_courses}"), t("answers.student_loan_start_date.#{claim.student_loan_courses}.#{claim.student_loan_start_date}"), "student-loan-start-date"] if claim.student_loan_courses.present?
      a << [t("student_loans.questions.student_loan_amount", claim_school_name: claim.eligibility.claim_school_name), number_to_currency(claim.eligibility.student_loan_repayment_amount), "student-loan-amount"]
    end
  end

  def payment_answers(claim)
    [].tap do |a|
      a << ["Name on bank account", claim.banking_name, "bank-details"]
      a << ["Bank sort code", claim.bank_sort_code, "bank-details"]
      a << ["Bank account number", claim.bank_account_number, "bank-details"]
      a << ["Building society roll number", claim.building_society_roll_number, "bank-details"] if claim.building_society_roll_number.present?
    end
  end

  def subject_list(subjects)
    connector = " and "
    translated_subjects = subjects.map { |subject| I18n.t("student_loans.questions.eligible_subjects.#{subject}") }
    translated_subjects.sort.to_sentence(
      last_word_connector: connector,
      two_words_connector: connector
    )
  end

  def school_search_question(searching_for_additional_school)
    searching_for_additional_school ? t("student_loans.questions.additional_school") : t("student_loans.questions.claim_school")
  end
end
