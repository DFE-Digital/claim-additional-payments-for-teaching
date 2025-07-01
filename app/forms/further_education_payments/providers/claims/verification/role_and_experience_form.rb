module FurtherEducationPayments
  module Providers
    module Claims
      module Verification
        class RoleAndExperienceForm < BaseForm
          attribute :provider_verification_teaching_responsibilities, :boolean
          attribute :provider_verification_in_first_five_years, :boolean
          attribute :provider_verification_teaching_qualification, :string
          attribute :provider_verification_contract_type, :string
          attribute :section_completed, :boolean

          validates(
            :provider_verification_teaching_responsibilities,
            inclusion: {
              in: ->(form) { form.teaching_responsibilities_options.map(&:id) }
            }
          )

          validates(
            :provider_verification_in_first_five_years,
            inclusion: {
              in: ->(form) { form.in_first_five_years_options.map(&:id) }
            }
          )

          validates(
            :provider_verification_teaching_qualification,
            inclusion: {
              in: ->(form) { form.teaching_qualification_options.map(&:id) }
            }
          )

          validates(
            :provider_verification_contract_type,
            inclusion: {
              in: ->(form) { form.contract_type_options.map(&:id) }
            }
          )

          # TBD decide how we want to handle this
          # validates :section_completed, inclusion: { in: [true, false] }

          def provider_name
            provider.name
          end

          def claimant_name
            claim.full_name
          end

          def teaching_responsibilities_options
            [
              Form::Option.new(id: true, name: "Yes"),
              Form::Option.new(id: false, name: "No")
            ]
          end

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

          def contract_type_options
            [
              Form::Option.new(id: "permanent", name: "Permanent"),
              Form::Option.new(id: "fixed_term", name: "Fixed-term"),
              Form::Option.new(id: "variable_hours", name: "Variable hours")
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
        end
      end
    end
  end
end
