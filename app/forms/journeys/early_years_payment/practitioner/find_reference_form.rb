module Journeys
  module EarlyYearsPayment
    module Practitioner
      class FindReferenceForm < Form
        attribute :reference_number, :string
        attribute :email, :string

        validates :reference_number, presence: {message: i18n_error_message(:presence)}

        def save
          return false if invalid?

          existing_claim = Claim
            .by_policy(Policies::EarlyYearsPayments)
            .find_by(reference: reference_number, practitioner_email_address: email)

          journey_session.answers.assign_attributes(
            reference_number:,
            start_email: email,
            reference_number_found: existing_claim.present?,
            claim_already_submitted: existing_claim&.eligibility&.practitioner_claim_submitted?,
            nursery_name: existing_claim&.eligibility&.eligible_ey_provider&.nursery_name
          )
          journey_session.save!
        end
      end
    end
  end
end
