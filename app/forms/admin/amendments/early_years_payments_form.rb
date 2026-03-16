module Admin
  module Amendments
    class EarlyYearsPaymentsForm < Admin::AmendmentForm
      attribute :practitioner_email_address, :string

      validates :practitioner_email_address,
        email_address_format: {
          message: "Email address must be in the correct format"
        },
        length: {
          maximum: Rails.application.config.email_max_length,
          message: "Email address must be less than %{length} characters"
        },
        if: -> { practitioner_email_address.present? }

      def load_data_from_claim
        super

        self.practitioner_email_address = claim.practitioner_email_address
      end
    end
  end
end
