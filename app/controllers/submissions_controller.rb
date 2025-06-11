class SubmissionsController < BasePublicController
  include PartOfClaimJourney

  skip_before_action :send_unstarted_claimants_to_the_start, only: [:show]
  skip_before_action :check_whether_closed_for_submissions, only: [:show]

  def create
    @form = journey::ClaimSubmissionForm.new(journey_session: journey_session)

    if @form.save
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
