module Admin
  module Amendments
    class EarlyYearsPaymentsForm < Admin::AmendmentForm
      attribute :practitioner_email_address, :string

      validates :practitioner_email_address, presence: {
        message: "Enter the practitioner's email address"
      }

      validates :practitioner_email_address,
        email_address_format: {
          message: "Email address must be in the correct format"
        },
        length: {
          maximum: Rails.application.config.email_max_length,
          message: "Email address must be less than %{length} characters"
        }

      def load_data_from_claim
        super

        self.practitioner_email_address = claim.practitioner_email_address
      end

      def valid?
        result = super

        return result unless only_provider_journey_compeleted?

        # EY claims only have partial details until the practitioner has
        # completed their journey, as such the base amendment form adds errors
        # for fields we don't have values for (bank_account_number etc) which we
        # need to clear to allow the `practitioner_email_address` to be changed.
        # Some errors, eg requiring a note we also want to preserve.

        errors.map(&:attribute).each do |attr|
          unless attr.in? %i[base practitioner_email_address notes]
            errors.delete(attr)
          end
        end

        errors.none?
      end

      private

      def only_provider_journey_compeleted?
        claim.submitted_at.blank?
      end
    end
  end
end
