module PartOfClaimJourney
  extend ActiveSupport::Concern

  included do
    before_action :set_cache_headers
    before_action :check_whether_closed_for_submissions, if: :current_policy_routing_name
    before_action :send_unstarted_claimants_to_the_start, if: :send_to_start?
    helper_method :current_claim, :submitted_claim
  end

  private

  def current_policy_routing_name
    super || current_claim.policy&.routing_name
  end

  def check_whether_closed_for_submissions
    unless journey_configuration.open_for_submissions?
      @availability_message = journey_configuration.availability_message
      render "static_pages/closed_for_submissions", status: :service_unavailable
    end
  end

  def send_unstarted_claimants_to_the_start
    redirect_to current_policy.start_page_url, allow_other_host: true
  end

  def current_claim_persisted?
    current_claim.persisted?
  end

  def skip_landing_page?
    params[:skip_landing_page] == "true"
  end

  def send_to_start?
    !skip_landing_page? && !current_claim_persisted?
  end

  def current_claim
    @current_claim ||= claim_from_session || build_new_claim
  end

  def submitted_claim
    return unless session[:submitted_claim_id]
    CurrentClaim.new(claims: Claim.where(id: session[:submitted_claim_id]))
  end

  def claim_from_session
    return unless session.key?(:claim_id)

    selected_policy = if session[:selected_claim_policy].present?
      Policies.constantize(session[:selected_claim_policy])
    end

    claims = Claim.includes(:eligibility).where(id: session[:claim_id])
    claims.present? ? CurrentClaim.new(claims: claims, selected_policy: selected_policy) : nil
  end

  def build_new_claim
    CurrentClaim.new(claims: build_new_claims)
  end

  def build_new_claims
    journey_configuration.policies.map do |policy|
      Claim.new(
        eligibility: policy::Eligibility.new,
        academic_year: journey_configuration.current_academic_year
      )
    end
  end

  def journey_configuration
    @journey_configuration ||= JourneyConfiguration.for_routing_name(current_policy_routing_name)
  end

  def set_cache_headers
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end
end
