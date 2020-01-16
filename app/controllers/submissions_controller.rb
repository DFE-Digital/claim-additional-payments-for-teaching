class SubmissionsController < BasePublicController
  include PartOfClaimJourney

  def create
    if current_claim.submit!
      ClaimMailer.submitted(current_claim).deliver_later
      RecordClaimEventJob.perform_later([current_claim.id], :submitted, :submitted_at)
      redirect_to claim_confirmation_path
    else
      render "claims/check_your_answers"
    end
  end

  def show
    render :show
    clear_claim_session
  end
end
