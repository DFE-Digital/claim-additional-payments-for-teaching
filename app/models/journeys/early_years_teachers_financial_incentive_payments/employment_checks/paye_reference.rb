module Journeys
  module EarlyYearsTeachersFinancialIncentivePayments
    module EmploymentChecks
      class PayeReference
        def initialize(setting:, employments:)
          @setting = setting
          @employments = employments
        end

        def result
          return nil unless usable?

          if setting.multiple_nurseries? && registered_person_has_ineligible_nurseries?
            Result.new(
              check: :employer_paye_reference,
              passed?: false,
              failure_reason: :registered_person_has_ineligible_nurseries
            )
          else
            Result.new(
              check: :employer_paye_reference,
              passed?: true,
              failure_reason: nil
            )
          end
        end

        def usable?
          employments.any? do
            employer_paye_reference_matches?(it.fetch("employer"))
          end
        end

        private

        attr_reader :setting, :employments

        def registered_person_has_ineligible_nurseries?
          Policies::EarlyYearsTeachersFinancialIncentivePayments::EligibleEytfiProvider
            .where(
              file_upload_id: setting.file_upload_id,
              registered_person_name: setting.registered_person_name,
              eligible: false
            ).exists?
        end

        def employer_paye_reference_matches?(employer)
          setting.paye_reference.present? &&
            setting.paye_reference == employer["payeReference"]
        end
      end
    end
  end
end
