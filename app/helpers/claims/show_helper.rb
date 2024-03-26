module Claims
  module ShowHelper
    def shared_view_css_class_size(claim)
      claim.has_ecp_or_lupp_policy? ? "l" : "xl"
    end

    def policy_name(claim)
      claim.policy.short_name.downcase.singularize
    end

    def award_amount(claim)
      number_to_currency(claim.award_amount, precision: 0)
    end
  end
end
