module FurtherEducationPayments
  module Providers
    module Claims
      module Verification
        class ContractTypeForm < BaseForm
          attribute :provider_verification_contract_type, :string

          validates(
            :provider_verification_contract_type,
            inclusion: {
              in: ->(form) { form.contract_type_options.map(&:id) },
              message: "Enter the type of contract they have"
            },
            unless: :save_and_exit?
          )

          def contract_type_options
            [
              Form::Option.new(id: "permanent", name: "Permanent"),
              Form::Option.new(id: "fixed_term", name: "Fixed-term"),
              Form::Option.new(id: "variable_hours", name: "Variable hours"),
              Form::Option.new(
                id: "employed_by_another_organisation",
                name: "Employed by another organisation (for example, an agency or contractor)"
              )
            ]
          end
        end
      end
    end
  end
end
