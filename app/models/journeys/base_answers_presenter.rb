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
        a << payroll_gender
        a << teacher_reference_number if show_trn?
        a << [t("questions.national_insurance_number"), answers.national_insurance_number, "personal-details"] if show_nino?
        a << [t("questions.email_address"), answers.email_address, "email-address"] unless show_email_select?
        a << [text_for(:select_email), answers.email_address, "select-email"] if show_email_select?
        a << [t("questions.provide_mobile_number"), answers.provide_mobile_number? ? "Yes" : "No", "provide-mobile-number"] unless show_mobile_select?
        a << [t("questions.mobile_number"), answers.mobile_number, "mobile-number"] unless show_mobile_select? || !answers.provide_mobile_number?
        a << [t("forms.select_mobile_form.questions.which_number"), answers.mobile_number.present? ? answers.mobile_number : t("forms.select_mobile_form.answers.decline"), "select-mobile"] if show_mobile_select?
      end
    end

    def payment_answers
      [].tap do |a|
        a << ["Name on bank account", answers.banking_name, "personal-bank-account"]
        a << ["Bank sort code", answers.bank_sort_code, "personal-bank-account"]
        a << ["Bank account number", answers.bank_account_number, "personal-bank-account"]
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

    def payroll_gender
      [t("forms.gender.questions.payroll_gender"), t("answers.payroll_gender.#{answers.payroll_gender}"), "gender"]
    end

    def teacher_reference_number
      [text_for(:teacher_reference_number), answers.teacher_reference_number, "teacher-reference-number"]
    end
  end
end
