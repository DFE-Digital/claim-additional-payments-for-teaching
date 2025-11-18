module FurtherEducationPayments
  module Providers
    module Claims
      module Verification
        class TeachingQualificationForm < BaseForm
          TEACHING_QUALIFICATION_OPTIONS = [
            Form::Option.new(
              id: "yes",
              name: I18n.t(
                %w[
                  further_education_payments_provider
                  forms
                  verification
                  provider_verification_teaching_qualification
                  options
                  yes
                ].join(".")
              )
            ),
            Form::Option.new(
              id: "not_yet",
              name: I18n.t(
                %w[
                  further_education_payments_provider
                  forms
                  verification
                  provider_verification_teaching_qualification
                  options
                  not_yet
                ].join(".")
              )
            ),
            Form::Option.new(
              id: "no_but_planned",
              name: I18n.t(
                %w[
                  further_education_payments_provider
                  forms
                  verification
                  provider_verification_teaching_qualification
                  options
                  no_but_planned
                ].join(".")
              )
            ),
            Form::Option.new(
              id: "no_not_planned",
              name: I18n.t(
                %w[
                  further_education_payments_provider
                  forms
                  verification
                  provider_verification_teaching_qualification
                  options
                  no_not_planned
                ].join(".")
              )
            )
          ]

          attribute :provider_verification_teaching_qualification, :string

          validates(
            :provider_verification_teaching_qualification,
            included: {
              in: ->(form) { form.teaching_qualification_options.map(&:id) },
              message: ->(form, _) do
                "Select if #{form.claimant_name} has a teaching qualification"
              end
            },
            allow_nil: :save_and_exit?
          )

          def teaching_qualification_options
            TEACHING_QUALIFICATION_OPTIONS
          end
        end
      end
    end
  end
end
