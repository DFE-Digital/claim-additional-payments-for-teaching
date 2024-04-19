class OmniauthCallbacksController < ApplicationController
  include JourneyConcern

  def callback
    auth = request.env["omniauth.auth"]

    SignInWithDfeIdentityForm.new(
      claim: current_claim,
      journey: journey,
      params: {
        teacher_id_user_info: auth.extra.raw_info.to_h.with_indifferent_access
      }
    ).save!

    # We get here after clicking a link on the "sign-in-or-continue"
    session[:slugs] ||= []
    session[:slugs] << "sign-in-or-continue"

    redirect_to claim_path(journey: current_journey_routing_name, slug: "teacher-detail")
  end

  def failure
    render layout: false
  end

  private

  # If for some reason the session is empty, redirect the user to the first available user journey
  def policy
    @policy ||= claim_from_session&.policy || Policies.all.first
  end

  def current_journey_routing_name
    Journeys.for_policy(policy)::ROUTING_NAME
  end
end
