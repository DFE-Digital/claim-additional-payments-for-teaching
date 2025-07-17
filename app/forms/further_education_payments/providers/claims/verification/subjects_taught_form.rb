module FurtherEducationPayments
  module Providers
    module Claims
      module Verification
        class SubjectsTaughtForm < BaseForm
          attribute :provider_verification_subjects_taught, :boolean

          validates(
            :provider_verification_subjects_taught,
            included: {
              in: ->(form) do
                form.provider_verification_subjects_taught_options.map(&:id)
              end
            },
            allow_nil: :save_and_exit?
          )

          def provider_verification_subjects_taught_options
            [
              Form::Option.new(id: true, name: "Yes"),
              Form::Option.new(id: false, name: "No")
            ]
          end

          def subjects_taught_descriptions
            claim.eligibility.courses_taught.map(&:description)
          end
        end
      end
    end
  end
end
