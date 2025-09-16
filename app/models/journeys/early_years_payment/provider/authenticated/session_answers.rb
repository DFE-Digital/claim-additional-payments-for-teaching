module Journeys
  module EarlyYearsPayment
    module Provider
      module Authenticated
        class SessionAnswers < Journeys::SessionAnswers
          attribute :consent_given, :boolean, pii: false
          attribute :nursery_urn, pii: true
          attribute :paye_reference, pii: true
          attribute :start_date, :date, pii: false
          attribute :provider_entered_contract_type, :string, pii: false
          attribute :child_facing_confirmation_given, :boolean, pii: false
          attribute :returning_within_6_months, :boolean, pii: false
          attribute :returner_worked_with_children, :boolean, pii: false
          attribute :returner_contract_type, pii: false
          attribute :practitioner_email_address, pii: true
          attribute :provider_contact_name, pii: true
          attribute :provider_email_address, pii: true
          attribute :practitioner_first_name, pii: true
          attribute :practitioner_surname, pii: true
          attribute :invalid_magic_link, :boolean, pii: false

          def policy
            Policies::EarlyYearsPayments
          end

          def provide_mobile_number
            false
          end

          def eligible_ey_provider
            EligibleEyProvider
              .unscoped
              .order(created_at: :desc)
              .find_by(urn: nursery_urn)
          end
        end
      end
    end
  end
end
