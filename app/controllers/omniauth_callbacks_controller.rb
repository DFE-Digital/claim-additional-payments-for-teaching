class OmniauthCallbacksController < ApplicationController
  include JourneyConcern

  # TODO RL: once this works extract it into a DfeIdentityCallbackForm
  # pass auth.extra.raw_info.trn to the form as a param
  def callback
    # Handles user somehow using Back button to go back and choose "Continue
    # with DfE Identity" option. Or they sign in a second time,
    # `details_check` needs resetting in case details are different.
    DfeIdentity::ClaimUserDetailsReset.call(current_claim, :new_user_info)

    auth = request.env["omniauth.auth"]

    teacher_id_user_info = auth.extra.raw_info

    if teacher_id_user_info.dig(:trn).present?
      current_claim.update!(teacher_id_user_info: teacher_id_user_info)
    end

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
