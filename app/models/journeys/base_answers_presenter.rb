module Journeys
  class BaseAnswersPresenter
    attr_reader :journey_session

    delegate :answers, to: :journey_session

    def initialize(journey_session)
      @journey_session = journey_session
    end

    def identity_answers
      [].tap do |a|
        a << [t("questions.name"), answers.full_name, "personal-details"] if show_name?
        a << [t("forms.address.questions.your_address"), answers.address, "address"]
        a << [t("questions.date_of_birth"), date_of_birth_string, "personal-details"] if show_dob?
        a << [t("forms.gender.questions.payroll_gender"), t("answers.payroll_gender.#{answers.payroll_gender}"), "gender"]
        a << [t("questions.teacher_reference_number"), answers.teacher_reference_number, "teacher-reference-number"] if show_trn?
        a << [t("questions.national_insurance_number"), answers.national_insurance_number, "personal-details"] if show_nino?
        a << [t("questions.email_address"), answers.email_address, "email-address"] unless show_email_select?
        a << [text_for(:select_email), answers.email_address, "select-email"] if show_email_select?
        a << [t("questions.provide_mobile_number"), answers.provide_mobile_number? ? "Yes" : "No", "provide-mobile-number"] unless show_mobile_select?
        a << [t("questions.mobile_number"), answers.mobile_number, "mobile-number"] unless show_mobile_select? || !answers.provide_mobile_number?
        a << [t("additional_payments.forms.select_mobile_form.questions.which_number"), answers.mobile_number.present? ? answers.mobile_number : t("additional_payments.forms.select_mobile_form.answers.decline"), "select-mobile"] if show_mobile_select?
      end
    end

    def payment_answers
      change_slug = answers.building_society? ? "building-society-account" : "personal-bank-account"
      [].tap do |a|
        a << [t("questions.bank_or_building_society"), answers.bank_or_building_society.to_s.humanize, "bank-or-building-society"]
        a << ["Name on bank account", answers.banking_name, change_slug]
        a << ["Bank sort code", answers.bank_sort_code, change_slug]
        a << ["Bank account number", answers.bank_account_number, change_slug]
        a << ["Building society roll number", answers.building_society_roll_number, change_slug] if answers.building_society_roll_number.present?
      end
    end

    private

    def text_for(form, key = form)
      t("forms.#{form}.questions.#{key}")
    end

    def date_of_birth_string
      answers.date_of_birth && l(answers.date_of_birth)
    end

    def show_name?
      !(answers.logged_in_with_tid? && answers.name_same_as_tid?)
    end

    def show_dob?
      !(answers.logged_in_with_tid? && answers.dob_same_as_tid?)
    end

    def show_nino?
      !(answers.logged_in_with_tid? && answers.nino_same_as_tid?)
    end

    def show_trn?
      !(answers.logged_in_with_tid? && answers.trn_same_as_tid?)
    end

    def show_email_select?
      answers.logged_in_with_tid? && answers.email_address_check?
    end

    def show_mobile_select?
      answers.logged_in_with_tid? && answers.mobile_check.present?
    end
  end
end
