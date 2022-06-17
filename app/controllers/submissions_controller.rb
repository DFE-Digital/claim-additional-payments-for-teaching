class SubmissionsController < BasePublicController
  include PartOfClaimJourney

  def create
    current_claim.submit!(session[:selected_claim_policy])

    ClaimMailer.submitted(current_claim.main_claim).deliver_later
    ClaimVerifierJob.perform_later(current_claim.main_claim)

    redirect_to current_claim.has_ecp_policy? ? claim_completion_path : claim_confirmation_path
  rescue Claim::NotSubmittable
    current_claim.valid?(:submit)
    render "claims/check_your_answers"
  end

  # Clear session unless this was an ECP policy. If ECP policy, user has
  # oppotunity to set a reminder up where name and email is re-used from claim.
  def show
    render :show
    clear_claim_session unless current_claim.has_ecp_policy?
  end
end
