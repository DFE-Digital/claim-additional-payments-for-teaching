module Admin
  module ClaimSummaryHelper
    def claim_summary_view
      policy_name_to_append = @claim.policy.to_s.underscore if @claim.policy.is_a?(Policies::FurtherEducationPayments)
      ["claim_summary", policy_name_to_append].compact.join("_")
    end
  end
end
