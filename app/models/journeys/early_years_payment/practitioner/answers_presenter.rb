module Journeys
  module EarlyYearsPayment
    module Practitioner
      class AnswersPresenter < BaseAnswersPresenter
        include ActionView::Helpers::TranslationHelper

        def identity_answers
          [].tap do |a|
            a << ["Full name", answers.full_name, "full-name"] if show_full_name?
            a << ["Date of birth", date_of_birth_string, "date-of-birth"] if show_date_of_birth?
            a << ["National Insurance number", answers.national_insurance_number, "national-insurance-number"]
            a << ["Home address", answers.address, "address"]
            a << ["Preferred email address", answers.email_address, "email-address"]
            a << ["Provide mobile number?", answers.provide_mobile_number? ? "Yes" : "No", "provide-mobile-number"]
            a << ["Preferred mobile number", answers.mobile_number, "mobile-number"] if answers.provide_mobile_number?
          end
        end

        def payment_answers
          [].tap do |a|
            a << ["Name on the account", answers.banking_name, "personal-bank-account"]
            a << ["Sort code", answers.bank_sort_code, "personal-bank-account"]
            a << ["Account number", answers.bank_account_number, "personal-bank-account"]
            a << ["Payroll gender", t("answers.payroll_gender.#{answers.payroll_gender}"), "gender"]
          end
        end

        private

        def show_full_name?
          !answers.identity_confirmed_with_onelogin?
        end

        def show_date_of_birth?
          !answers.identity_confirmed_with_onelogin?
        end
      end
    end
  end
end
