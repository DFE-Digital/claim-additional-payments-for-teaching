module Journeys
  module EarlyYearsPayment
    module Provider
      module Authenticated
        class SessionAnswers < Journeys::SessionAnswers
          attribute :consent_given, :boolean
          attribute :nursery_urn
          attribute :paye_reference
          attribute :start_date, :date
          attribute :child_facing_confirmation_given, :boolean
          attribute :returning_within_6_months, :boolean
          attribute :returner_worked_with_children, :boolean
          attribute :returner_contract_type
          attribute :practitioner_email_address
          attribute :provider_contact_name
          attribute :provider_email_address
          attribute :practitioner_first_name
          attribute :practitioner_surname

          def policy
            Policies::EarlyYearsPayments
          end

          def provide_mobile_number
            false
          end
        end
      end
    end
  end
end
