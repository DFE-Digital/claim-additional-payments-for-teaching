module ClaimsHelper
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

  def eligibility_answers(claim)
    claim.policy::EligibilityAnswersPresenter.new(claim.eligibility).answers
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

  def school_search_question(searching_for_additional_school)
    searching_for_additional_school ? t("student_loans.questions.additional_school") : t("student_loans.questions.claim_school")
  end
end
