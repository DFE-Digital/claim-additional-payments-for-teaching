module AuthorisedSlugs
  extend ActiveSupport::Concern

  included do
    before_action :authorise_slug!
  end

  def authorise_slug!
    if page_sequence.requires_authorisation?(current_slug) && !authorised?
      redirect_to(
        page_sequence.unauthorised_path(
          current_slug,
          authorisation.failure_reason
        )
      )
    end
  end

  def authorised?
    authorisation.failure_reason.nil?
  end

  def authorisation
    journey::Authorisation.new(
      answers: journey_session.answers,
      slug: current_slug
    )
  end
end
