module PartOfClaimJourney
  extend ActiveSupport::Concern

  included do
    before_action :set_cache_headers
    before_action :check_whether_closed_for_submissions, if: :current_policy_routing_name
    before_action :send_unstarted_claimants_to_the_start
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

  def send_unstarted_claimants_to_the_start
    redirect_to current_policy.start_page_url unless current_claim.persisted?
  end

  # Keep this for StudentLoans and MathsAndPhysics journeys
  # Keep ECP journey working for now with current_claim as we build out combined journey
  def current_claim
    @current_claim ||= claim_from_session || build_new_claim
  end

  # TASK: does NOT support multiple claims yet!
  def claim_from_session
    Claim.find(session[:claim_id]) if session.key?(:claim_id)
  end

  def build_new_claim
    CurrentClaim.new(claims: build_new_claims)
  end

  # Beginning of setting up multiple claims in a combined journey
  def build_new_claims
    Journey.policies_for_routing_name(current_policy_routing_name).map do |policy|
      Claim.new(
        eligibility: policy::Eligibility.new,
        academic_year: policy_configuration.current_academic_year
      )
    end
  end

  def policy_configuration
    @policy_configuration ||= Journey.policy_configuration_for(current_policy_routing_name)
  end

  def set_cache_headers
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end
end
