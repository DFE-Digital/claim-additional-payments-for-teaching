module FurtherEducationPayments
  module Providers
    module Claims
      module Verification
        class QualificationForm < BaseForm
          attribute :provider_verification_in_first_five_years, :boolean
          attribute :provider_verification_teaching_qualification, :string

          validates(
            :provider_verification_in_first_five_years,
            included: {
              in: ->(form) { form.in_first_five_years_options.map(&:id) }
            },
            allow_nil: :save_and_exit?
          )

          validates(
            :provider_verification_teaching_qualification,
            included: {
              in: ->(form) { form.teaching_qualification_options.map(&:id) }
            },
            allow_nil: :save_and_exit?
          )

          def in_first_five_years_options
            [
              Form::Option.new(id: true, name: "Yes"),
              Form::Option.new(id: false, name: "No")
            ]
          end

          def teaching_qualification_options
            [
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
          end
        end
      end
    end
  end
end
