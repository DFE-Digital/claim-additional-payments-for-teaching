module FurtherEducationPayments
  module Providers
    module Claims
      module Verification
        class TaughtAtLeastOneAcademicTermForm < BaseForm
          attribute(
            :provider_verification_taught_at_least_one_academic_term,
            :boolean
          )

          validates(
            :provider_verification_taught_at_least_one_academic_term,
            inclusion: {
              in: ->(form) do
                form.taught_at_least_one_academic_term_options.map(&:id)
              end
            },
            unless: :save_and_exit?
          )

          def taught_at_least_one_academic_term_options
            [
              Form::Option.new(id: true, name: "Yes"),
              Form::Option.new(id: false, name: "No")
            ]
          end
        end
      end
    end
  end
end
