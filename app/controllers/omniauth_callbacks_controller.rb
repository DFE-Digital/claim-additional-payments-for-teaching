class OmniauthCallbacksController < ApplicationController
  include JourneyConcern

  ONELOGIN_JWT_CORE_IDENTITY_HASH_KEY = "https://vocab.account.gov.uk/v1/coreIdentityJWT".freeze

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
    case params[:strategy]
    when "onelogin"
      render OneLogin::FailureHandler.new(
        message: params[:message],
        origin: params[:origin],
        answers: journey_session.answers
      ).template
    else
      render layout: false
    end
  end

  def onelogin
    auth = if OneLoginSignIn.bypass?
      test_user_auth_hash
    else
      request.env["omniauth.auth"]
    end

    core_identity_jwt = auth.extra.raw_info[ONELOGIN_JWT_CORE_IDENTITY_HASH_KEY]
    return process_one_login_identity_verification_callback(core_identity_jwt) if core_identity_jwt
    process_one_login_authentication_callback(auth)
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

  def process_one_login_authentication_callback(auth)
    onelogin_user_info = auth.info.to_h.slice("email", "phone")
    onelogin_credentials = auth.credentials

    journey_session.answers.assign_attributes(
      onelogin_uid: auth.uid,
      onelogin_user_info:,
      onelogin_credentials:,
      logged_in_with_onelogin: true
    )
    journey_session.save!

    redirect_to(
      claim_path(
        journey: current_journey_routing_name,
        slug: "sign-in"
      )
    )
  end

  def process_one_login_identity_verification_callback(core_identity_jwt)
    if request.env["omniauth.auth"].uid != journey_session.answers.onelogin_uid
      origin = claim_url(
        journey: current_journey_routing_name,
        slug: "sign-in"
      )
      return redirect_to "/auth/failure?strategy=onelogin&message=access_denied&origin=#{origin}"
    end

    first_name, surname = extract_name_from_jwt(core_identity_jwt)

    journey_session.answers.assign_attributes(
      identity_confirmed_with_onelogin: true
    )
    journey_session.answers.first_name ||= first_name
    journey_session.answers.surname ||= surname
    journey_session.save!

    redirect_to(
      claim_path(
        journey: current_journey_routing_name,
        slug: "sign-in"
      )
    )
  end

  def extract_name_from_jwt(jwt)
    if OneLoginSignIn.bypass?
      first_name = "TEST"
      surname = "USER"
    else
      validator = OneLogin::CoreIdentityValidator.new(jwt:)
      validator.call
      first_name = validator.first_name
      surname = validator.surname
    end
    [first_name, surname]
  end

  def test_user_auth_hash
    if request.path == "/auth/onelogin"
      OmniAuth::AuthHash.new(info: {email: "test@example.com"}, extra: {raw_info: {}})
    elsif request.path == "/auth/onelogin_identity"
      OmniAuth::AuthHash.new(info: {email: ""}, extra: {raw_info: {ONELOGIN_JWT_CORE_IDENTITY_HASH_KEY => "test"}})
    end
  end
end
