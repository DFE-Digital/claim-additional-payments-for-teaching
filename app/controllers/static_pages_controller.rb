class StaticPagesController < BasePublicController
  def accessibility_statement
  end

  def contact_us
  end

  def cookies_page
  end

  def terms_conditions
  end

  def landing_page
    @academic_year = journey.configuration.current_academic_year

    @journey_open = journey.open_for_submissions?(params[:service_access_code])

    render "#{journey::VIEW_PATH}/landing_page"
  end
end
