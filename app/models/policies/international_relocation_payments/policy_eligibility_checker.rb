module Policies
  module InternationalRelocationPayments
    class PolicyEligibilityChecker
      attr_reader :answers

      delegate_missing_to :answers

      def initialize(answers:)
        @answers = answers
      end

      def status
        return :ineligible if ineligible?

        :eligible_now
      end

      def ineligible?
        ineligible_reason.present?
      end

      private

      def ineligible_reason
        case answers.attributes.symbolize_keys
        in application_route: "salaried_trainee"
          "application route salaried trainee not accecpted"
        in application_route: "other"
          "application route other not accecpted"
        in state_funded_secondary_school: false
          "school not state funded"
        in application_route: "teacher", one_year: false
          "teacher contract duration of less than one year not accepted"
        in subject: "other"
          "taught subject not accepted"
        in visa_type: "Other"
          "visa not accepted"
        in date_of_entry: Date, start_date: Date unless date_of_entry_eligible?
          "cannot enter the UK more than 3 months before your contract start date"
        else
          nil
        end
      end

      def date_of_entry_eligible?
        return false unless answers.date_of_entry && answers.start_date

        answers.date_of_entry >= answers.start_date - 3.months
      end
    end
  end
end
