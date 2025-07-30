module FurtherEducationPayments
  module Providers
    module Claims
      module Verification
        class ActualSubjectsTaughtForm < BaseForm
          include Journeys::FurtherEducationPayments::CoursesHelper

          attribute :provider_verification_actual_subjects_taught, default: []

          before_validation :clean_subjects_taught

          validates(
            :provider_verification_actual_subjects_taught,
            presence: {
              message: "Select the subject area they teach"
            },
            unless: :save_and_exit?
          )

          validates(
            :provider_verification_actual_subjects_taught,
            included: {
              in: ->(form) { form.checkbox_options.map(&:id) },
              message: "Select the subject area they teach"
            },
            allow_blank: :save_and_exit?
          )

          def checkbox_options
            options = ALL_SUBJECTS.map do |subject|
              Form::Option.new(
                id: subject,
                name: I18n.t("further_education_payments.forms.subjects_taught.options.#{subject}")
              )
            end

            options << Form::Option.new(
              id: "none",
              name: "They do not teach any of these subject areas"
            )

            options
          end

          private

          def clean_subjects_taught
            provider_verification_actual_subjects_taught.reject!(&:blank?)
          end
        end
      end
    end
  end
end
