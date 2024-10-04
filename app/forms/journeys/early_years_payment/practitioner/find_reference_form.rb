module Journeys
  module EarlyYearsPayment
    module Practitioner
      class FindReferenceForm < Form
        attribute :reference_number, :string
        attribute :email, :string

        validates :reference_number, presence: {message: i18n_error_message(:presence)}

        def save
          return false if invalid?

          journey_session.answers.assign_attributes(
            reference_number:,
            start_email: email,
            reference_number_found: claim_exists?
          )
          journey_session.save!
        end

        private

        def claim_exists?
          Claim
            .by_policy(Policies::EarlyYearsPayments)
            .where(reference: reference_number)
            .where(practitioner_email_address: email)
            .exists?
        end
      end
    end
  end
end
