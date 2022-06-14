module Claims
  module ShowHelper
    def claim_submitted_title(claim)
      if claim.has_ecp_policy?
        content_tag(:h1, "Application complete", class: "govuk-panel__title", id: "submitted-title")
      else
        content_tag(:h1, "Claim submitted", class: "govuk-panel__title", id: "submitted-title")
      end
    end

    def shared_view_css_class_size(claim)
      claim.has_ecp_policy? ? "l" : "xl"
    end

    def policy_name(claim)
      claim.policy.short_name.downcase.singularize
    end

    def award_amount(claim)
      number_to_currency(claim.award_amount, precision: 0)
    end
  end
end
