module Journeys
  class BaseAnswersPresenter
    attr_reader :claim, :eligibility

    def initialize(claim)
      @claim = claim
      @eligibility = claim.eligible_eligibility
    end

    def identity_answers
      [].tap do |a|
        a << [translate("questions.name"), claim.full_name, "personal-details"] if show_name?
        a << [translate("questions.address.generic.title"), claim.address, "address"] unless claim.address_from_govuk_verify?
        a << [translate("questions.date_of_birth"), date_of_birth_string, "personal-details"] if show_dob?
        a << [translate("questions.payroll_gender"), t("answers.payroll_gender.#{claim.payroll_gender}"), "gender"] unless claim.payroll_gender_verified?
        a << [translate("questions.teacher_reference_number"), claim.teacher_reference_number, "teacher-reference-number"] if show_trn?
        a << [translate("questions.national_insurance_number"), claim.national_insurance_number, "personal-details"] if show_nino?
        a << [translate("questions.email_address"), claim.email_address, claim.email_address_check? ? "select-email" : "email-address"]
      end
    end

    def student_loan_answers
      [].tap do |a|
        a << [translate("questions.has_student_loan"), (claim.has_student_loan ? "Yes" : "No"), "student-loan"]
        a << [translate("questions.student_loan_country"), claim.student_loan_country.titleize, "student-loan-country"] if claim.student_loan_country.present?
        a << [translate("questions.student_loan_how_many_courses"), claim.student_loan_courses.humanize, "student-loan-how-many-courses"] if claim.student_loan_courses.present?
        a << [translate("questions.student_loan_start_date.#{claim.student_loan_courses}"), t("answers.student_loan_start_date.#{claim.student_loan_courses}.#{claim.student_loan_start_date}"), "student-loan-start-date"] if claim.student_loan_courses.present?
        a << [translate("questions.has_masters_and_or_doctoral_loan"), (claim.has_masters_doctoral_loan ? "Yes" : "No"), "masters-doctoral-loan"] if claim.no_student_loan?
        a << [translate("questions.postgraduate_masters_loan"), (claim.postgraduate_masters_loan ? "Yes" : "No"), "masters-loan"] unless claim.no_masters_doctoral_loan?
        a << [translate("questions.postgraduate_doctoral_loan"), (claim.postgraduate_doctoral_loan ? "Yes" : "No"), "doctoral-loan"] unless claim.no_masters_doctoral_loan?
      end
    end

    def payment_answers
      change_slug = claim.building_society? ? "building-society-account" : "personal-bank-account"
      [].tap do |a|
        a << [translate("questions.bank_or_building_society"), claim.bank_or_building_society.to_s.humanize, "bank-or-building-society"]
        a << ["Name on bank account", claim.banking_name, change_slug]
        a << ["Bank sort code", claim.bank_sort_code, change_slug]
        a << ["Bank account number", claim.bank_account_number, change_slug]
        a << ["Building society roll number", claim.building_society_roll_number, change_slug] if claim.building_society_roll_number.present?
      end
    end

    private

    def date_of_birth_string
      claim.date_of_birth && l(claim.date_of_birth)
    end

    def show_name?
      !(claim.logged_in_with_tid? && claim.name_same_as_tid?)
    end

    def show_dob?
      !(claim.logged_in_with_tid? && claim.dob_same_as_tid?)
    end

    def show_nino?
      !(claim.logged_in_with_tid? && claim.nino_same_as_tid?)
    end

    def show_trn?
      !(claim.logged_in_with_tid? && claim.trn_same_as_tid?)
    end
  end
end
