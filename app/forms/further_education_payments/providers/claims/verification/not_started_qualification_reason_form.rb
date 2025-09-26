module FurtherEducationPayments
  module Providers
    module Claims
      module Verification
        class NotStartedQualificationReasonForm < BaseForm
          attribute(
            :provider_verification_not_started_qualification_reasons,
            default: []
          )

          attribute(
            :provider_verification_not_started_qualification_reason_other,
            :string
          )

          validate :selected_options_are_valid

          validates(
            :provider_verification_not_started_qualification_reason_other,
            presence: {
              message: ->(form, _) do
                "Enter the reason why #{form.claim.full_name} has not yet " \
                "started or completed a teaching qualification"
              end
            },
            if: -> do
              provider_verification_not_started_qualification_reasons.include?("other")
            end
          )

          def provider_verification_not_started_qualification_reason_options
            %w[
              workload
              funding_issues
              course_not_available_at_the_right_time
              cant_access_suitable_course
              new_member_of_staff
              no_valid_reason
            ]
          end

          def label_for(reason)
            I18n.t(
              reason,
              scope: %w[
                further_education_payments
                providers
                claims
                verification
                forms
                not_started_qualification_reason
                options
              ].join(".")
            )
          end

          private

          def selected_options_are_valid
            unless selected_options_are_valid?
              errors.add(
                :provider_verification_not_started_qualification_reasons,
                "Select the reason or reasons why #{claim.full_name} has not " \
                "yet started or completed a teaching qualification"
              )
            end
          end

          def selected_options_are_valid?
            if provider_verification_not_started_qualification_reasons.empty?
              return true if save_and_exit?
              return false
            end

            valid_reasons = provider_verification_not_started_qualification_reason_options + ["other"]

            provider_verification_not_started_qualification_reasons.all? do |option|
              valid_reasons.include?(option)
            end
          end
        end
      end
    end
  end
end
