module FurtherEducationPayments
  module Providers
    module Claims
      module Verification
        class PerformanceAndDisciplineForm < BaseForm
          attribute :provider_verification_performance_measures, :boolean
          attribute :provider_verification_disciplinary_action, :boolean

          attribute(
            :provider_verification_performance_section_completed,
            :boolean
          )

          validates(
            :provider_verification_performance_measures,
            included: {
              in: ->(form) { form.performance_measures_options.map(&:id) }
            },
            allow_nil: :save_and_exit?
          )

          validates(
            :provider_verification_disciplinary_action,
            included: {
              in: ->(form) { form.disciplinary_action_options.map(&:id) }
            },
            allow_nil: :save_and_exit?
          )

          validates(
            :provider_verification_performance_section_completed,
            inclusion: {
              in: ->(form) { form.section_completed_options.map(&:id) }
            }
          )

          def performance_measures_options
            [
              Form::Option.new(id: true, name: "Yes"),
              Form::Option.new(id: false, name: "No")
            ]
          end

          def disciplinary_action_options
            [
              Form::Option.new(id: true, name: "Yes"),
              Form::Option.new(id: false, name: "No")
            ]
          end

          def section_completed_options
            [
              Form::Option.new(id: true, name: "Yes"),
              Form::Option.new(
                id: false,
                name: "No, I want to come back to it later"
              )
            ]
          end

          def save_and_exit?
            provider_verification_performance_section_completed == false
          end
        end
      end
    end
  end
end
