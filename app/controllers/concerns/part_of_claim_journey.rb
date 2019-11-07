module PartOfClaimJourney
  extend ActiveSupport::Concern

  included do
    before_action :check_whether_closed_for_submissions, if: :current_policy_routing_name
    before_action :send_unstarted_claiments_to_the_start
    helper_method :current_claim
  end

  private

  def current_policy_routing_name
    current_claim.policy&.routing_name
  end

  def check_whether_closed_for_submissions
    policy = Policies[current_policy_routing_name]
    policy_configuration = PolicyConfiguration.find_by(policy_type: policy.name)

    unless policy_configuration.open_for_submissions?
      @availability_message = policy_configuration.availability_message
      render "static_pages/maintenance", status: :service_unavailable
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

  private

  def routing_policy
    Policies[params[:policy]]
  end

  def routing_eligibility
    routing_policy && routing_policy::Eligibility.new
  end
end
