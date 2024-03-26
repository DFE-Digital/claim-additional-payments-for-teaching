module JourneyConcern
  extend ActiveSupport::Concern

  included do
    helper_method :current_journey_routing_name, :journey, :journey_configuration, :current_claim
  end

  def current_journey_routing_name
    params[:journey] || Journeys.for_policy(claim_from_session.policy)::ROUTING_NAME
  end

  def journey
    Journeys.for_routing_name(current_journey_routing_name)
  end

  def journey_configuration
    journey.configuration
  end

  def current_claim
    @current_claim ||= claim_from_session || build_new_claim
  end

  private

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
    journey::POLICIES.map do |policy|
      Claim.new(
        eligibility: policy::Eligibility.new,
        academic_year: journey_configuration.current_academic_year
      )
    end
  end
end
