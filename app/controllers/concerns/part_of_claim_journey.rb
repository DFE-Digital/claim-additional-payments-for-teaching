module PartOfClaimJourney
  extend ActiveSupport::Concern

  included do
    before_action :set_cache_headers
    before_action :check_whether_closed_for_submissions, if: :current_journey_routing_name
    before_action :send_unstarted_claimants_to_the_start, if: :send_to_start?
    helper_method :submitted_claim
  end

  private

  def check_whether_closed_for_submissions
    return if session[:submitted_claim_id].present?

    unless journey.accessible?(access_code)
      @availability_message = journey_configuration.availability_message
      render "static_pages/closed_for_submissions", status: :service_unavailable
    end
  end

  def access_code
    if journey_session
      journey_session.answers.service_access_code
    else
      # We've been redirected from the landing page and this callback
      # is running before the new action, so we're yet to create the
      # journey session.
      params.fetch(:answers, {})[:service_access_code]
    end
  end

  def send_unstarted_claimants_to_the_start
    redirect_to journey.start_page_url, allow_other_host: true
  end

  def skip_landing_page?
    params[:skip_landing_page] == "true"
  end

  def send_to_start?
    !skip_landing_page? && journey_sessions.none?
  end

  def submitted_claim
    return unless session[:submitted_claim_id]

    Claim.by_policies_for_journey(journey).find_by(id: session[:submitted_claim_id])
  end

  def set_cache_headers
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end
end
