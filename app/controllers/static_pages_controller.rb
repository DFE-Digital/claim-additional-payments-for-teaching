class StaticPagesController < BasePublicController
  def accessibility_statement
  end

  def contact_us
  end

  def cookies
  end

  def privacy_notice
  end

  def terms_conditions
  end

  def landing_page
    current_policy = JourneyConfiguration.policy_for_routing_name(current_journey_routing_name)

    jc = JourneyConfiguration.for(current_policy)
    @academic_year = jc.current_academic_year

    render "#{JourneyConfiguration.view_path(current_journey_routing_name)}/landing_page"
  end
end
