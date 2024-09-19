module Admin
  module ClaimSummaryHelper
    def claim_summary_view
      case @claim.policy
      when Policies::FurtherEducationPayments
        "claim_summary_further_education_payments"
      when Policies::InternationalRelocationPayments
        "claim_summary_international_relocation_payments"
      else
        "claim_summary"
      end
    end
  end
end
