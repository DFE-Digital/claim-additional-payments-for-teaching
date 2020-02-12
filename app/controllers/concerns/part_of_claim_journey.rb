module PartOfClaimJourney
  extend ActiveSupport::Concern

  included do
    before_action :set_cache_headers
    before_action :check_whether_closed_for_submissions, if: :current_policy_routing_name
    before_action :send_unstarted_claiments_to_the_start
    helper_method :current_claim
  end

  private

  def current_policy_routing_name
    super || current_claim.policy&.routing_name
  end

  def check_whether_closed_for_submissions
    unless policy_configuration.open_for_submissions?
      @availability_message = policy_configuration.availability_message
      render "static_pages/closed_for_submissions", status: :service_unavailable
    end
  end

  def send_unstarted_claiments_to_the_start
    redirect_to routing_policy.start_page_url unless current_claim.persisted?
  end

  def current_claim
    @current_claim ||= claim_from_session || Claim.new(eligibility: routing_eligibility)
  end

  def claim_from_session
    Claim.find(session[:claim_id]) if session.key?(:claim_id)
  end

  def policy_configuration
    @policy_configuration ||= PolicyConfiguration.find_by(policy_type: current_policy.name)
  end

  # Returns the policy module that matches the current routing. Note this is
  # subtly different to `current_policy`, which is more robust and will fall-
  # back to the policy of the `current_claim` when the routing is not scoped to
  # a `:policy`, for example with the GOV.UK Verify-related routes.
  #
  # You will almost certainly want to use `current_policy` most of the time.
  def routing_policy
    Policies[params[:policy]]
  end

  def routing_eligibility
    routing_policy && routing_policy::Eligibility.new
  end

  def set_cache_headers
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end
end
