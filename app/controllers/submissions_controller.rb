class SubmissionsController < BasePublicController
  include PartOfClaimJourney

  skip_before_action :send_unstarted_claimants_to_the_start, only: [:show]

  def create
    current_claim.submit!(session[:selected_claim_policy])

    ClaimMailer.submitted(current_claim.main_claim).deliver_later
    ClaimVerifierJob.perform_later(current_claim.main_claim)

    session[:submitted_claim_id] = current_claim.id
    clear_claim_session

    redirect_to submitted_claim.has_ecp_or_lupp_policy? ? claim_completion_path : claim_confirmation_path
  rescue Claim::NotSubmittable
    current_claim.valid?(:submit)
    render "claims/check_your_answers"
  end

  def show
    return redirect_to current_policy.start_page_url, allow_other_host: true unless submitted_claim
  end
end
