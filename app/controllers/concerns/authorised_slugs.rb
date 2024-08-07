module AuthorisedSlugs
  extend ActiveSupport::Concern

  included do
    before_action :authorise_slug!
  end

  def authorise_slug!
    if current_slug_requires_authorisation? && !authorised?
      redirect_to_slug(page_sequence.authorisation_start(current_slug))
    end
  end

  def authorised?
    journey::Authorisation.new(journey_session.answers).authorised?(current_slug)
  end

  def current_slug_requires_authorisation?
    page_sequence.requires_authorisation?(current_slug)
  end
end

