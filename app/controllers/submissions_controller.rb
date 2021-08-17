class SubmissionsController < BasePublicController
  include PartOfClaimJourney

  def create
    if current_claim.submit!
      ClaimMailer.submitted(current_claim).deliver_later
      RecordOrUpdateGeckoboardDatasetJob.perform_later([current_claim.id])
      ClaimVerifierJob.perform_later(current_claim)

      redirect_to current_claim.has_ecp_policy? ? claim_completion_path : claim_confirmation_path
    else
      render "claims/check_your_answers"
    end
  end

  def show
    render :show
    clear_claim_session unless current_claim.has_ecp_policy?
  end
end
