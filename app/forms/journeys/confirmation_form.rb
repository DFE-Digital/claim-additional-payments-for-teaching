module Journeys
  class ConfirmationForm < Form
    class SubmittedClaimNotFound < StandardError; end

    delegate :reference, :email_address, to: :submitted_claim

    private

    def submitted_claim
      @submitted_claim ||= Claim
        .by_policies_for_journey(journey)
        .find(session[:submitted_claim_id])
    rescue ActiveRecord::RecordNotFound
      raise SubmittedClaimNotFound
    end
  end
end
