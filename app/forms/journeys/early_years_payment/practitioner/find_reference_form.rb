module Journeys
  module EarlyYearsPayment
    module Practitioner
      class FindReferenceForm < Form
        attribute :reference_number, :string

        validates :reference_number, presence: {message: i18n_error_message(:presence)}

        def save
          return false if invalid?

          existing_claim = Claim
            .by_policy(Policies::EarlyYearsPayments)
            .find_by(reference: reference_number)

          journey_session.answers.assign_attributes(
            reference_number:,
            reference_number_found: existing_claim.present?,
            claim_already_submitted: existing_claim&.submitted?,
            nursery_name: existing_claim&.eligibility&.eligible_ey_provider&.nursery_name
          )
          journey_session.save!
        end
      end
    end
  end
end
