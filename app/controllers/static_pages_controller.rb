class StaticPagesController < BasePublicController
  def accessibility_statement
    journey_accessibility_statement = "#{journey.view_path}/accessibility_statement"

    if lookup_context.template_exists?(journey_accessibility_statement, [], false)
      render journey_accessibility_statement
    else
      render "static_pages/accessibility_statement"
    end
  end

  def contact_us
  end

  def cookies_page
  end

  def terms_conditions
  end

  def landing_page
    @academic_year = journey.configuration.current_academic_year

    @journey_open = journey.accessible?(params[:service_access_code])

    render "#{journey.view_path}/landing_page"
  end

  private

  def current_user
    DfeSignIn::NullUser.new
  end
  helper_method :current_user
end
