class OmniauthCallbacksController < ApplicationController
  include JourneyConcern

  def callback
    auth = request.env["omniauth.auth"]

    # Only keep the attributes permitted by the form
    teacher_id_user_info_attributes = auth.extra.raw_info.to_h.slice(
      *SignInOrContinueForm::TeacherIdUserInfoForm::DFE_IDENTITY_ATTRIBUTES.map(&:to_s)
    )

    redirect_to(
      claim_path(
        journey: current_journey_routing_name,
        slug: "sign-in-or-continue",
        claim: {
          logged_in_with_tid: true,
          teacher_id_user_info_attributes: teacher_id_user_info_attributes
        }
      )
    )
  end

  def failure
    render layout: false
  end

  def onelogin
    auth = request.env["omniauth.auth"]
    # TODO need public key to decode and verify jwt
    # jwt = auth.extra.raw_info["https://vocab.account.gov.uk/v1/coreIdentityJWT"]
    # JSON::JWT.decode(jwt, public_key)
    # contains: GivenName, FamilyName
    redirect_to(
      claim_path(
        journey: current_journey_routing_name,
        slug: "sign-in",
        claim: {
          logged_in_with_onelogin: true,
          email_address: auth.info.email
        }
      )
    )
  rescue Rack::OAuth2::Client::Error => e
    render plain: e.message
  end

  private

  def current_journey_routing_name
    if session[:current_journey_routing_name].present?
      session[:current_journey_routing_name]
    else
      # If for some reason the session is empty, redirect the user to the first
      # available user journey
      Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME
    end
  end
end
