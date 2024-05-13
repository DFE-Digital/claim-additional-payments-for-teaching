class SubmissionsController < BasePublicController
  include PartOfClaimJourney

  skip_before_action :send_unstarted_claimants_to_the_start, only: [:show]

  def create
    shim = ClaimJourneySessionShim.new(
      current_claim: current_claim,
      journey_session: journey_session
    )

    @form = ClaimSubmissionForm.new(journey_session: shim)

    if @form.save
      current_claim.claims.each(&:destroy!)

      session[:submitted_claim_id] = @form.claim.id
      clear_claim_session
      redirect_to claim_confirmation_path
    else
      render "claims/check_your_answers"
    end
  end

  def show
    redirect_to journey.start_page_url, allow_other_host: true unless submitted_claim
  end
end
