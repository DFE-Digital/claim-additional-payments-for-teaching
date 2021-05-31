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

    def base_and_uplift_award_amounts(claim, year)
      return nil unless claim.has_ecp_policy?

      base_amount = MATRIX.dig(claim.eligibility.eligible_itt_subject, claim.eligibility.itt_academic_year, year)
      uplifted = case base_amount
      when 0
        0
      when 2000
        3000
      when 5000
        7500
      end

      {base: BigDecimal(base_amount), uplifted: BigDecimal(uplifted)}
    end
  end
end
