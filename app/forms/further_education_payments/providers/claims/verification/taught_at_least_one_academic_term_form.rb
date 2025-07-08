module FurtherEducationPayments
  module Providers
    module Claims
      module Verification
        class TaughtAtLeastOneAcademicTermForm < BaseForm
          attribute(
            :provider_verification_taught_at_least_one_academic_term,
            :boolean
          )

          attribute(
            :provider_verification_taught_one_term_section_completed,
            :boolean
          )

          validates(
            :provider_verification_taught_at_least_one_academic_term,
            included: {
              in: ->(form) do
                form.taught_at_least_one_academic_term_options.map(&:id)
              end
            },
            allow_nil: :save_and_exit?
          )

          validates(
            :provider_verification_taught_one_term_section_completed,
            inclusion: {
              in: ->(form) { form.section_completed_options.map(&:id) }
            }
          )

          def taught_at_least_one_academic_term_options
            [
              Form::Option.new(id: true, name: "Yes"),
              Form::Option.new(id: false, name: "No")
            ]
          end

          def section_completed_options
            [
              Form::Option.new(
                id: true,
                name: "Yes"
              ),
              Form::Option.new(
                id: false,
                name: "No, I want to come back to it later"
              )
            ]
          end

          def save_and_exit?
            provider_verification_taught_one_term_section_completed == false
          end
        end
      end
    end
  end
end
