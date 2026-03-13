module Journeys
  module EarlyYearsTeachers
    module Practitioner
      class AnswersPresenter < BaseAnswersPresenter
        def eligibility_answers
          [].tap do |a|
            a << full_name_answer
            a << date_of_birth_answer
            a << national_insurance_number_answer
            a << teacher_reference_number_answer
          end
        end

        def payment_answers
          [].tap do |a|
            a << accept_payment_answer
            a << payment_option_answer
          end
        end

        def contact_answers
          [].tap do |a|
            a << home_address_answer
          end
        end

        def payroll_answers
          [].tap do |a|
            a << banking_name_answer
            a << bank_sort_code_answer
            a << bank_account_number_answer
            a << gender_answer
          end
        end

        private

        def full_name_answer
          ["Full name", answers.full_name, "full-name"]
        end

        def date_of_birth_answer
          ["Date of birth", answers.date_of_birth&.to_fs(:long_uk), "date-of-birth"]
        end

        def national_insurance_number_answer
          ["National Insurance number", answers.national_insurance_number, "national-insurance-number"]
        end

        def teacher_reference_number_answer
          ["Teacher reference number (TRN)", answers.teacher_reference_number, "teacher-reference-number"]
        end

        def accept_payment_answer
          ["Accept payment", answers.accept_payment ? "Yes" : "No", "eligibility-confirmed"]
        end

        def payment_option_answer
          option_text = case answers.payment_option
          when "lump_sum"
            "One lump sum"
          when "monthly_instalments"
            "Monthly instalments"
          end
          ["Payment option", option_text, "payment-options"]
        end

        def home_address_answer
          ["Home address", answers.address("<br>").html_safe, "postcode-search"]
        end

        def banking_name_answer
          ["Name on bank account", answers.banking_name, "personal-bank-account"]
        end

        def bank_sort_code_answer
          ["Bank sort code", answers.bank_sort_code, "personal-bank-account"]
        end

        def bank_account_number_answer
          ["Bank account number", answers.bank_account_number, "personal-bank-account"]
        end

        def gender_answer
          gender_text = if answers.payroll_gender == "other"
            answers.payroll_gender_other
          else
            I18n.t(
              "early_years_teachers_practitioner.answers.payroll_gender.#{answers.payroll_gender}",
              default: I18n.t("answers.payroll_gender.#{answers.payroll_gender}", default: answers.payroll_gender)
            )
          end
          ["Gender", gender_text, "gender"]
        end
      end
    end
  end
end
