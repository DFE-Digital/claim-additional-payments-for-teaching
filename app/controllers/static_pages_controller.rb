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
    pc = PolicyConfiguration.for(current_policy)
    @academic_year = pc.current_academic_year

    render "#{PolicyConfiguration.view_path(pc.routing_name)}/landing_page"
  end
end
