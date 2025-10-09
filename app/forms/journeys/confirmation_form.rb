module Journeys
  class ConfirmationForm < Form
    delegate :reference, :email_address, to: :submitted_claim

    private

    def submitted_claim
      @submitted_claim ||= Claim
        .by_policies_for_journey(journey)
        .find(session[:submitted_claim_id])
    end
  end
end
