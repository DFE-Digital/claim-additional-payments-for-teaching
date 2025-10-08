module FurtherEducationPayments
  module Providers
    module Claims
      module Verification
        class ContractTypeForm < BaseForm
          attribute :provider_verification_contract_type, :string

          validates(
            :provider_verification_contract_type,
            included: {
              in: ->(form) { form.contract_type_options.map(&:id) },
              message: ->(form, _) do
                "Select the type of contract #{form.claimant_name} has directly " \
                "with #{form.provider_name}"
              end
            },
            allow_nil: :save_and_exit?
          )

          def contract_type_options
            [
              Form::Option.new(id: "permanent", name: "Permanent"),
              Form::Option.new(id: "fixed_term", name: "Fixed-term"),
              Form::Option.new(id: "variable_hours", name: "Variable hours"),
              Form::Option.new(
                id: "no_direct_contract",
                name: "Does not currently have a direct contract of employment with #{provider_name}",
                hint: "For example, they have left #{provider_name} or they are employed through an agency, as a contractor, or through a subsidiary of #{provider_name}."
              )
            ]
          end
        end
      end
    end
  end
end
