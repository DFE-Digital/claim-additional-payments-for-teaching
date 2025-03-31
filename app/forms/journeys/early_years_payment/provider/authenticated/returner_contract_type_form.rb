module Journeys
  module EarlyYearsPayment
    module Provider
      module Authenticated
        class ReturnerContractTypeForm < Form
          attribute :returner_contract_type, :string

          validates :returner_contract_type,
            inclusion: {in: ->(form) { form.radio_options.map(&:id) }, message: i18n_error_message(:inclusion)}

          def radio_options
            [
              Option.new(
                id: "permanent",
                name: t("options.permanent")
              ),
              Option.new(
                id: "casual or temporary",
                name: t("options.casual_or_temporary")
              ),
              Option.new(
                id: "voluntary or unpaid",
                name: t("options.voluntary_or_unpaid")
              ),
              Option.new(
                id: "agency work and apprenticeship roles",
                name: t("options.agency_work_and_apprenticeships")
              )
            ]
          end

          def save
            return false if invalid?

            journey_session.answers.assign_attributes(returner_contract_type:)
            journey_session.save!
          end
        end
      end
    end
  end
end
