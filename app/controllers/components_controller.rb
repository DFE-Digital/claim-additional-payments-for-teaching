class ComponentsController < BasePublicController
  skip_before_action :add_view_paths, only: [:home]
  before_action :set_home_journey, only: [:home]

  def home
    render layout: "application"
  end

  private

  def current_journey_routing_name
    super || journey&.routing_name
  end

  def set_home_journey
    @journey = Journeys::TargetedRetentionIncentivePayments
  end
end
