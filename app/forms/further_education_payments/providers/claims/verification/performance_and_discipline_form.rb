module FurtherEducationPayments
  module Providers
    module Claims
      module Verification
        class PerformanceAndDisciplineForm < BaseForm
          attribute :provider_verification_performance_measures, :boolean
          attribute :provider_verification_disciplinary_action, :boolean

          validates(
            :provider_verification_performance_measures,
            inclusion: {
              in: ->(form) { form.performance_measures_options.map(&:id) }
            },
            unless: :save_and_exit?
          )

          validates(
            :provider_verification_disciplinary_action,
            inclusion: {
              in: ->(form) { form.disciplinary_action_options.map(&:id) }
            },
            unless: :save_and_exit?
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
        end
      end
    end
  end
end
