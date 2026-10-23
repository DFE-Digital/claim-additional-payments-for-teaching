module Journeys
  module SchoolTargetedRetentionIncentivePayments
    class AnswersPresenter < BaseAnswersPresenter
      def employment_answers
        [
          ["School", answers.current_school.name, "current-school"],
          ["Qualifications", qualification_types.join(", ")]

        ]
      end

      def personal_answers
        [
          ["Name", answers.teacher_auth_verified_name, nil],
          ["Email address", answers.teacher_auth_email, nil],
          ["Home address", answers.address, "postcode-search"],
          [
            "Gender as it appears on your payroll",
            t("answers.payroll_gender.#{answers.payroll_gender}"),
            "gender"
          ],
          ["National Insurance number", answers.national_insurance_number, "verify-national-insurance-number"]
        ]
      end

      def bank_answers
        [
          ["Name on your account", answers.banking_name, "personal-bank-account"],
          ["Sort code", answers.bank_sort_code, "personal-bank-account"],
          ["Account number", answers.bank_account_number, "personal-bank-account"]
        ]
      end

      private

      def qualification_types
        answers
          .dqt_record
          .record
          .held_routes_to_professional_statuses
          .map do |r|
            r.type
          end
      end
    end
  end
end
