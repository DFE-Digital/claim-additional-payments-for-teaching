class SubmissionsController < BasePublicController
  include PartOfClaimJourney

  def create
    if current_claim.submit!
      # TODO - main_claim may need to be dealing with the `submitted_claim` here...
      ClaimMailer.submitted(current_claim.main_claim).deliver_later
      ClaimVerifierJob.perform_later(current_claim.main_claim)

      redirect_to current_claim.has_ecp_policy? ? claim_completion_path : claim_confirmation_path
    else
      current_claim.valid?(:submit)
      render "claims/check_your_answers"
    end
  end

  # Clear session unless this was an ECP policy. If ECP policy, user has
  # oppotunity to set a reminder up where name and email is re-used from claim.
  def show
    render :show
    clear_claim_session unless current_claim.has_ecp_policy?
  end
end
