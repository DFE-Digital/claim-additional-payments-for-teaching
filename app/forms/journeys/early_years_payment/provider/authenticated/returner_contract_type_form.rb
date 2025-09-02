module Journeys
  module EarlyYearsPayment
    module Provider
      module Authenticated
        class ReturnerContractTypeForm < Form
          attribute :returner_contract_type, :string

          validates :returner_contract_type,
            inclusion: {
              in: ->(form) {
                form.radio_options.map(&:id)
              },
              message: ->(form, data) {
                i18n_error_message(
                  :inclusion,
                  claimant_full_name: form.claimant_full_name
                ).call(form, data)
              }
            }

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

          def claimant_full_name
            journey_session.answers.full_name
          end
        end
      end
    end
  end
end
