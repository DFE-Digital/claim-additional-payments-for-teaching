module Journeys
  class BaseAnswersPresenter
    attr_reader :claim, :eligibility

    def initialize(claim)
      @claim = claim

      @eligibility = if @claim.is_a?(CurrentClaim)
        claim.eligible_eligibility
      else
        claim.eligibility
      end
    end

    def identity_answers
      [].tap do |a|
        a << [t("questions.name"), claim.full_name, "personal-details"] if show_name?
        a << [t("forms.address.questions.your_address"), claim.address, "address"] unless claim.address_from_govuk_verify?
        a << [t("questions.date_of_birth"), date_of_birth_string, "personal-details"] if show_dob?
        a << [t("forms.gender.questions.payroll_gender"), t("answers.payroll_gender.#{claim.payroll_gender}"), "gender"] unless claim.payroll_gender_verified?
        a << [t("questions.teacher_reference_number"), claim.teacher_reference_number, "teacher-reference-number"] if show_trn?
        a << [t("questions.national_insurance_number"), claim.national_insurance_number, "personal-details"] if show_nino?
        a << [t("questions.email_address"), claim.email_address, "email-address"] unless show_email_select?
        a << [text_for(:select_email), claim.email_address, "select-email"] if show_email_select?
        a << [t("questions.provide_mobile_number"), claim.provide_mobile_number? ? "Yes" : "No", "provide-mobile-number"] unless show_mobile_select?
        a << [t("questions.mobile_number"), claim.mobile_number, "mobile-number"] unless show_mobile_select? || !claim.provide_mobile_number?
        a << [t("additional_payments.forms.select_mobile_form.questions.which_number"), claim.mobile_number? ? claim.mobile_number : t("additional_payments.forms.select_mobile_form.answers.decline"), "select-mobile"] if show_mobile_select?
      end
    end

    def payment_answers
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

    def text_for(form, key = form)
      t("forms.#{form}.questions.#{key}")
    end

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

    def show_email_select?
      claim.logged_in_with_tid? && claim.email_address_check?
    end

    def show_mobile_select?
      claim.logged_in_with_tid? && claim.mobile_check.present?
    end
  end
end
