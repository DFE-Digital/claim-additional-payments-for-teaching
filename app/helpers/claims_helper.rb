module ClaimsHelper
  def eligibility_answers(claim)
    claim.policy::EligibilityAnswersPresenter.new(claim.eligibility).answers
  end

  def identity_answers(claim)
    [].tap do |a|
      if claim.has_ecp_policy?
        a << [translate("questions.name"), claim.full_name, "personal-details"] unless claim.name_verified?
      else
        a << [translate("questions.name"), claim.full_name, "name"] unless claim.name_verified?
      end

      a << [translate("questions.address.generic.title"), claim.address, "address"] unless claim.address_from_govuk_verify?

      if claim.has_ecp_policy?
        a << [translate("questions.date_of_birth"), date_of_birth_string(claim), "personal-details"] unless claim.date_of_birth_verified?
      else
        a << [translate("questions.date_of_birth"), date_of_birth_string(claim), "date-of-birth"] unless claim.date_of_birth_verified?
      end

      a << [translate("questions.payroll_gender"), t("answers.payroll_gender.#{claim.payroll_gender}"), "gender"] unless claim.payroll_gender_verified?
      a << [translate("questions.teacher_reference_number"), claim.teacher_reference_number, "teacher-reference-number"]

      a << if claim.has_ecp_policy?
        [translate("questions.national_insurance_number"), claim.national_insurance_number, "personal-details"]
      else
        [translate("questions.national_insurance_number"), claim.national_insurance_number, "national-insurance-number"]
      end

      a << [translate("questions.email_address"), claim.email_address, "email-address"]

      a << [translate("questions.provide_mobile_number"), (claim.provide_mobile_number ? "Yes" : "No"), "provide-mobile-number"] if claim.has_ecp_policy?
      a << [translate("questions.mobile_number"), claim.mobile_number, "mobile-number"] if claim.has_ecp_policy? && claim.provide_mobile_number?
    end
  end

  def student_loan_answers(claim)
    [].tap do |a|
      a << [translate("questions.has_student_loan"), (claim.has_student_loan ? "Yes" : "No"), "student-loan"]
      a << [translate("questions.student_loan_country"), claim.student_loan_country.titleize, "student-loan-country"] if claim.student_loan_country.present?
      a << [translate("questions.student_loan_how_many_courses"), claim.student_loan_courses.humanize, "student-loan-how-many-courses"] if claim.student_loan_courses.present?
      a << [translate("questions.student_loan_start_date.#{claim.student_loan_courses}"), t("answers.student_loan_start_date.#{claim.student_loan_courses}.#{claim.student_loan_start_date}"), "student-loan-start-date"] if claim.student_loan_courses.present?
      a << [translate("questions.has_masters_and_or_doctoral_loan"), (claim.has_masters_doctoral_loan ? "Yes" : "No"), "masters-doctoral-loan"] if claim.no_student_loan?
      a << [translate("questions.postgraduate_masters_loan"), (claim.postgraduate_masters_loan ? "Yes" : "No"), "masters-loan"] unless claim.no_masters_doctoral_loan?
      a << [translate("questions.postgraduate_doctoral_loan"), (claim.postgraduate_doctoral_loan ? "Yes" : "No"), "doctoral-loan"] unless claim.no_masters_doctoral_loan?
      a << [translate("student_loans.questions.student_loan_amount", financial_year: StudentLoans.current_financial_year), number_to_currency(claim.eligibility.student_loan_repayment_amount), "student-loan-amount"] if claim.has_tslr_policy?
    end
  end

  def payment_answers(claim)
    change_slug = claim.building_society? ? "building-society-account" : "personal-bank-account"
    [].tap do |a|
      a << [translate("questions.bank_or_building_society"), claim.bank_or_building_society.to_s.humanize, "bank-or-building-society"]
      a << ["Name on bank account", claim.banking_name, change_slug]
      a << ["Bank sort code", claim.bank_sort_code, change_slug]
      a << ["Bank account number", claim.bank_account_number, change_slug]
      a << ["Building society roll number", claim.building_society_roll_number, change_slug] if claim.building_society_roll_number.present?
    end
  end

  def date_of_birth_string(claim)
    claim.date_of_birth && l(claim.date_of_birth)
  end
end
