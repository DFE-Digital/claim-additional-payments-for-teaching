module PartOfClaimJourney
  extend ActiveSupport::Concern

  included do
    before_action :send_unstarted_claiments_to_the_start
    helper_method :current_claim
  end

  private

  def current_policy_routing_name
    current_claim.eligibility.class.parent.routing_name
  end

  def send_unstarted_claiments_to_the_start
    redirect_to StudentLoans.start_page_url unless current_claim.persisted?
  end

  def current_claim
    @current_claim ||= claim_from_session || Claim.new(eligibility: StudentLoans::Eligibility.new)
  end

  def claim_from_session
    Claim.find(session[:claim_id]) if session.key?(:claim_id)
  end
end
