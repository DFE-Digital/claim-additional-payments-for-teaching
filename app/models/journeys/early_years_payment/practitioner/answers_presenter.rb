module Journeys
  module EarlyYearsPayment
    module Practitioner
      class AnswersPresenter < BaseAnswersPresenter
        include ActionView::Helpers::TranslationHelper

        def identity_answers
          [].tap do |a|
            a << ["Full name", answers.full_name, "personal-details"]
            a << ["Date of birth", date_of_birth_string, "personal-details"]
            a << ["National Insurance number", answers.national_insurance_number, "personal-details"]
            a << ["Home address", answers.address, "enter-home-address"]
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
            a << ["Payroll gender", answers.payroll_gender, "gender"]
          end
        end
      end
    end
  end
end
