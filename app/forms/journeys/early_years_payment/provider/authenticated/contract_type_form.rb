module Journeys
  module EarlyYearsPayment
    module Provider
      module Authenticated
        class ContractTypeForm < Form
          attribute :provider_entered_contract_type, :string

          validates(
            :provider_entered_contract_type,
            inclusion: {
              in: ->(form) { form.radio_options.map(&:id) },
              message: i18n_error_message(:inclusion)
            }
          )

          def radio_options
            [
              Option.new(
                id: "permanent",
                name: t("options.permanent")
              ),
              Option.new(
                id: "casual_or_temporary",
                name: t("options.casual_or_temporary")
              ),
              Option.new(
                id: "voluntary_or_unpaid",
                name: t("options.voluntary_or_unpaid")
              ),
              Option.new(
                id: "agency_work_and_apprenticeship_roles",
                name: t("options.agency_work_and_apprenticeship_roles")
              )
            ]
          end

          def nursery_name
            Policies::EarlyYearsPayments::EligibleEyProvider
              .find_by(urn: answers.nursery_urn)
              .nursery_name
          end

          def practitioner_first_name
            answers.practitioner_first_name
          end

          def save
            return false unless valid?

            journey_session.answers.assign_attributes(
              provider_entered_contract_type: provider_entered_contract_type
            )

            journey_session.save!
          end
        end
      end
    end
  end
end
