class StaticPagesController < BasePublicController
  def accessibility_statement
  end

  def contact_us
  end

  def cookies
  end

  def terms_conditions
  end

  def landing_page
    journey = Journeys.for_routing_name(current_journey_routing_name)
    @academic_year = journey.configuration.current_academic_year
    @journey_open = journey.configuration.open_for_submissions?

    render "#{journey::VIEW_PATH}/landing_page"
  end
end
