class SubmissionsController < BasePublicController
  include PartOfClaimJourney

  skip_before_action :send_unstarted_claimants_to_the_start, only: [:show]

  def create
    @form = ClaimSubmissionForm.new(
      journey: journey,
      claim: current_claim,
      params: selected_claim_params
    )

    if @form.save
      session[:submitted_claim_id] = current_claim.id
      clear_claim_session
      redirect_to claim_confirmation_path
    else
      render "claims/check_your_answers"
    end
  end

  def show
    redirect_to journey.start_page_url, allow_other_host: true unless submitted_claim
  end

  private

  def selected_claim_params
    ActionController::Parameters.new(
      {
        claim: {
          selected_claim_policy: session[:selected_claim_policy]
        }
      }
    )
  end
end
