module Claims
  module ShowHelper
    def claim_submitted_title(claim)
      if claim.has_ecp_policy?
        content_tag(:h1, "Application complete", class: "govuk-panel__title", id: "submitted-title")
      else
        content_tag(:h1, "Claim submitted", class: "govuk-panel__title", id: "submitted-title")
      end
    end
  end
end
