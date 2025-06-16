module Policies
  module InternationalRelocationPayments
    class PolicyEligibilityChecker
      PRE_ACADEMIC_YEAR_WINDOW_LIMIT = 6.months

      def self.earliest_eligible_contract_start_date
        Journeys::GetATeacherRelocationPayment
          .configuration
          .current_academic_year
          .start_of_autumn_term - PRE_ACADEMIC_YEAR_WINDOW_LIMIT
      end

      attr_reader :answers

      delegate_missing_to :answers

      delegate :earliest_eligible_contract_start_date, to: :class

      def initialize(answers:)
        @answers = answers
      end

      def ineligible?
        ineligibility_reason.present?
      end

      def ineligibility_reason
        case answers.attributes.symbolize_keys
        in previous_payment_received: false
          "previous payment not received"
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
        in start_date: Date unless contract_start_date_eligible?
          "contract start date must be after #{earliest_eligible_contract_start_date}"
        in date_of_entry: Date, start_date: Date unless date_of_entry_eligible?
          "cannot enter the UK more than 3 months before your contract start date"
        in current_school_id: String unless current_school_eligible?
          "school not eligible"
        else
          nil
        end
      end

      private

      def contract_start_date_eligible?
        return false unless answers.start_date

        answers.start_date >= earliest_eligible_contract_start_date
      end

      def date_of_entry_eligible?
        return false unless answers.date_of_entry && answers.start_date

        answers.date_of_entry >= answers.start_date - 3.months
      end

      def current_school_eligible?
        return false unless answers.current_school

        answers.current_school.secondary_or_equivalent? && answers.current_school.state_funded?
      end
    end
  end
end
