class StaticPagesController < BasePublicController
  include JourneyComponentsPage

  skip_before_action :add_view_paths, only: [:home, :journey_components, :customer_journeys]

  def accessibility_statement
    journey_accessibility_statement = "#{journey.view_path}/accessibility_statement"

    if lookup_context.template_exists?(journey_accessibility_statement, [], false)
      render journey_accessibility_statement
    else
      render "static_pages/accessibility_statement"
    end
  end

  def home
  end

  def customer_journeys
  end

  def journey_components
    prepare_journey_components_page
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

    if journey_available?
      render "#{journey.view_path}/landing_page"
    else
      render file: Rails.root.join("public", "404.html"),
        status: :not_found,
        layout: false
    end
  end

  def guidance_page
    guidance_page = "#{journey.view_path}/guidance"

    if journey_available? && lookup_context.template_exists?(guidance_page, [], false)
      render guidance_page
    else
      render(
        file: Rails.root.join("public", "404.html"),
        status: :not_found,
        layout: false
      )
    end
  end

  def methodology_page
    methodology_page = "#{journey.view_path}/methodology"

    if journey_available? && lookup_context.template_exists?(methodology_page, [], false)
      render methodology_page
    else
      render(
        file: Rails.root.join("public", "404.html"),
        status: :not_found,
        layout: false
      )
    end
  end

  def good_practice_page
    good_practice_page = "#{journey.view_path}/good_practice"

    if journey_available? && lookup_context.template_exists?(good_practice_page, [], false)
      render good_practice_page
    else
      render(
        file: Rails.root.join("public", "404.html"),
        status: :not_found,
        layout: false
      )
    end
  end

  def claim_cancelled
    claim_cancelled_page = "#{journey.view_path}/claims/claim_cancelled"

    if lookup_context.template_exists?(claim_cancelled_page, [], false)
      render claim_cancelled_page
    else
      render(
        file: Rails.root.join("public", "404.html"),
        status: :not_found,
        layout: false
      )
    end
  end

  private

  def current_journey_routing_name
    super || Journeys.all.first.routing_name
  end

  def journey_available?
    return true unless journey

    journey.available?
  end

  def current_user
    DfeSignIn::NullUser.new
  end
  helper_method :current_user
end
