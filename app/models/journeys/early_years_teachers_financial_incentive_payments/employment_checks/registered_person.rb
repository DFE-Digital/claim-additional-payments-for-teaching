module Journeys
  module EarlyYearsTeachersFinancialIncentivePayments
    module EmploymentChecks
      class RegisteredPerson
        def initialize(setting:, employments:)
          @setting = setting
          @employments = employments
        end

        def usable?
          registered_persons_nurseries.exists?
        end

        def result
          return nil unless usable?

          if registered_persons_nurseries.exclude?(setting)
            Result.new(
              check: :registered_person,
              passed?: false,
              failure_reason: :registered_person_does_not_match_setting
            )
          elsif registered_persons_nurseries.exists?(
            registered_person_name: setting.registered_person_name,
            eligible: false
          )
            Result.new(
              check: :registered_person,
              passed?: false,
              failure_reason: :registered_person_has_ineligible_nurseries
            )
          else
            Result.new(
              check: :registered_person,
              passed?: true,
              failure_reason: nil
            )
          end
        end

        private

        attr_reader :setting, :employments

        def employer_names
          @employer_names ||= employments.filter_map do
            it.dig("employer", "name").presence
          end.uniq
        end

        def registered_persons_nurseries
          Policies::EarlyYearsTeachersFinancialIncentivePayments::EligibleEytfiProvider
            .where(registered_person_name: employer_names)
            .where(file_upload: setting.file_upload)
        end
      end
    end
  end
end
