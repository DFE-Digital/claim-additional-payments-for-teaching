module FurtherEducationPayments
  module Providers
    module Claims
      module Verification
        class TeachingQualificationForm < BaseForm
          TEACHING_QUALIFICATION_OPTIONS = [
            Form::Option.new(
              id: "yes",
              name: "Yes"
            ),
            Form::Option.new(
              id: "not_yet",
              name: "Not yet, but is enrolled on one"
            ),
            Form::Option.new(
              id: "no_but_planned",
              name: "No, but is planning to enrol on one"
            ),
            Form::Option.new(
              id: "no_not_planned",
              name: "No, and has no plan to enrol on one in the next 12 months"
            )
          ]

          attribute :provider_verification_teaching_qualification, :string

          validates(
            :provider_verification_teaching_qualification,
            included: {
              in: ->(form) { form.teaching_qualification_options.map(&:id) },
              message: "Tell us if they have a teaching qualification"
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
