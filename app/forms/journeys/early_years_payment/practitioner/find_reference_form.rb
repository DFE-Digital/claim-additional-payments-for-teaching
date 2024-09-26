module Journeys
  module EarlyYearsPayment
    module Practitioner
      class FindReferenceForm < Form
        attribute :reference_number, :string

        validates :reference_number, presence: {message: i18n_error_message(:presence)}
        validate :validate_permissible_reference_number

        def save
          return false if invalid?

          journey_session.answers.assign_attributes(reference_number:)
          journey_session.save!
        end

        private

        def claim_exists?
          Claim
            .by_policy(Policies::EarlyYearsPayments)
            .where(reference: reference_number)
            .exists?
        end

        def validate_permissible_reference_number
          unless claim_exists?
            errors.add(
              :reference_number,
              :impermissible,
              message: self.class.i18n_error_message(:impermissible)
            )
          end
        end
      end
    end
  end
end
