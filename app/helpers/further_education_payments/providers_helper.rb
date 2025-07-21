module FurtherEducationPayments
  module ProvidersHelper
    include Policies::FurtherEducationPayments::ProviderVerificationConstants

    def claim_status_tag(claim)
      status = claim.eligibility.provider_verification_status

      tag_attributes = case status
      when STATUS_NOT_STARTED
        {text: "Not started", colour: "red"}
      when STATUS_IN_PROGRESS
        {text: "In progress", colour: "yellow"}
      when STATUS_COMPLETED
        {text: "Completed", colour: "green"}
      else
        {text: "Unknown", colour: "grey"}
      end

      govuk_tag(**tag_attributes)
    end
  end
end
