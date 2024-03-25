module ClaimsHelper
  def eligibility_answers(current_claim)
    current_claim.policy::EligibilityAnswersPresenter.new(current_claim.eligible_eligibility).answers
  end

  def identity_answers(claim)
    [].tap do |answers|
      answers << [t("questions.name"), claim.full_name, "personal-details"] if show_name(claim)
      answers << [t("questions.address.generic.title"), claim.address, "address"] unless claim.address_from_govuk_verify?
      answers << [t("questions.date_of_birth"), date_of_birth_string(claim), "personal-details"] if show_dob(claim)
      answers << [t("questions.payroll_gender"), t("answers.payroll_gender.#{claim.payroll_gender}"), "gender"] unless claim.payroll_gender_verified?
      answers << [t("questions.teacher_reference_number"), claim.teacher_reference_number, "teacher-reference-number"] if show_trn(claim)
      answers << [t("questions.national_insurance_number"), claim.national_insurance_number, "personal-details"] if show_nino(claim)

      answers.concat(email_answers(claim))
      answers.concat(mobile_answers(claim))
    end
  end

  def student_loan_answers(claim)
    [].tap do |a|
      a << [t("questions.has_student_loan"), (claim.has_student_loan ? "Yes" : "No"), "student-loan"]
      a << [t("questions.student_loan_country"), claim.student_loan_country.titleize, "student-loan-country"] if claim.student_loan_country.present?
      a << [t("questions.student_loan_how_many_courses"), claim.student_loan_courses.humanize, "student-loan-how-many-courses"] if claim.student_loan_courses.present?
      a << [t("questions.student_loan_start_date.#{claim.student_loan_courses}"), t("answers.student_loan_start_date.#{claim.student_loan_courses}.#{claim.student_loan_start_date}"), "student-loan-start-date"] if claim.student_loan_courses.present?
      a << [t("questions.has_masters_and_or_doctoral_loan"), (claim.has_masters_doctoral_loan ? "Yes" : "No"), "masters-doctoral-loan"] if claim.no_student_loan?
      a << [t("questions.postgraduate_masters_loan"), (claim.postgraduate_masters_loan ? "Yes" : "No"), "masters-loan"] unless claim.no_masters_doctoral_loan?
      a << [t("questions.postgraduate_doctoral_loan"), (claim.postgraduate_doctoral_loan ? "Yes" : "No"), "doctoral-loan"] unless claim.no_masters_doctoral_loan?
      a << [t("student_loans.questions.student_loan_amount", financial_year: Policies::StudentLoans.current_financial_year), number_to_currency(claim.eligibility.student_loan_repayment_amount), "student-loan-amount"] if claim.has_tslr_policy?
    end
  end

  def payment_answers(claim)
    change_slug = claim.building_society? ? "building-society-account" : "personal-bank-account"
    [].tap do |a|
      a << [t("questions.bank_or_building_society"), claim.bank_or_building_society.to_s.humanize, "bank-or-building-society"]
      a << ["Name on bank account", claim.banking_name, change_slug]
      a << ["Bank sort code", claim.bank_sort_code, change_slug]
      a << ["Bank account number", claim.bank_account_number, change_slug]
      a << ["Building society roll number", claim.building_society_roll_number, change_slug] if claim.building_society_roll_number.present?
    end
  end

  private

  def date_of_birth_string(claim)
    claim.date_of_birth && l(claim.date_of_birth)
  end

  def additional_payments_open?
    Journeys::AdditionalPaymentsForTeaching.configuration.open_for_submissions?
  end

  def show_name(claim)
    !(claim.logged_in_with_tid? && claim.name_same_as_tid?)
  end

  def show_dob(claim)
    !(claim.logged_in_with_tid? && claim.dob_same_as_tid?)
  end

  def show_nino(claim)
    !(claim.logged_in_with_tid? && claim.nino_same_as_tid?)
  end

  def show_trn(claim)
    !(claim.logged_in_with_tid? && claim.trn_same_as_tid?)
  end

  def email_answers(claim)
    [].tap do |answers|
      return answers << [t("questions.email_address"), claim.email_address, "email-address"] unless claim.logged_in_with_tid?

      # TID-route
      answers << if claim.email_address_check?
        [t("questions.select_email.heading"), claim.email_address, "select-email"]
      else
        # When an email selection couldn't be made, we don't want to link back to the `select-email`
        # slug, but rather to `email-address`. This indicates that an email was provided
        # manually due to it not being present in Teacher ID.
        [t("questions.email_address"), claim.email_address, "email-address"]
      end
    end
  end

  def mobile_answers(claim)
    [].tap do |answers|
      unless claim.logged_in_with_tid?
        answers << [t("questions.provide_mobile_number"), claim.provide_mobile_number? ? "Yes" : "No", "provide-mobile-number"]
        answers << [t("questions.mobile_number"), claim.mobile_number, "mobile-number"] if claim.provide_mobile_number?

        return answers
      end

      # TID-route
      if claim.mobile_check.present?
        select_mobile_answer = claim.mobile_number? ? claim.mobile_number : t("questions.select_phone_number.decline")
        answers << [t("questions.select_phone_number.heading"), select_mobile_answer, "select-mobile"]
      else
        # When a mobile number selection couldn't be made, we don't want to link back to the
        # `select-mobile` slug, but rather to `mobile-number`. This indicates that a mobile number
        # may have been provided manually due to it not being present in Teacher ID. We also need to
        # show the answer to the `provide-mobile-number` question and allow the user to change it.
        answers << [t("questions.provide_mobile_number"), claim.provide_mobile_number? ? "Yes" : "No", "provide-mobile-number"]
        answers << [t("questions.mobile_number"), claim.mobile_number, "mobile-number"] if claim.provide_mobile_number?
      end
    end
  end
end
