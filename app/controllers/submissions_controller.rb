class SubmissionsController < BasePublicController
  include PartOfClaimJourney
  include ClaimSubmission

  skip_before_action :send_unstarted_claimants_to_the_start, only: [:show]
  skip_before_action :check_whether_closed_for_submissions, only: [:show]

  def create
    create_and_save_claim_form
  end

  def show
    redirect_to journey.start_page_url, allow_other_host: true unless submitted_claim
  end
end
