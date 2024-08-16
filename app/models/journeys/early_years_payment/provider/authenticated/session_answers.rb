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
          attribute :first_job_within_6_months, :boolean

          def policy
            Policies::EarlyYearsPayments
          end
        end
      end
    end
  end
end
