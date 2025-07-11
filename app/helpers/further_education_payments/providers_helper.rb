module FurtherEducationPayments
  module ProvidersHelper
    def claim_status_tag(claim)
      status = claim.eligibility.provider_verification_status

      tag_attributes = case status
      when "not_started"
        {text: "Not started", colour: "red"}
      when "in_progress"
        {text: "In progress", colour: "yellow"}
      else
        {text: "Unknown", colour: "grey"}
      end

      govuk_tag(**tag_attributes)
    end
  end
end
