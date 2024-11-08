module Journeys
  module EarlyYearsPayment
    module Practitioner
      class SessionAnswers < Journeys::SessionAnswers
        attribute :reference_number, :string
        attribute :reference_number_found, :boolean, default: nil
        attribute :claim_already_submitted, :boolean, default: nil
        attribute :nursery_name
        attribute :start_email, :string
        attribute :practitioner_claim_started_at, :datetime

        def policy
          Policies::EarlyYearsPayments
        end
      end
    end
  end
end
