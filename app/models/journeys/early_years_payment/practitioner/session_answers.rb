module Journeys
  module EarlyYearsPayment
    module Practitioner
      class SessionAnswers < Journeys::SessionAnswers
        attribute :reference_number, :string, pii: false
        attribute :reference_number_found, :boolean, default: nil, pii: false
        attribute :claim_already_submitted, :boolean, default: nil, pii: false
        attribute :nursery_name, pii: true
        attribute :start_email, :string, pii: true
        attribute :practitioner_claim_started_at, :datetime, pii: false

        def policy
          Policies::EarlyYearsPayments
        end
      end
    end
  end
end
