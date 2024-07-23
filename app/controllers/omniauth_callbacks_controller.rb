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
    auth = if OneLoginSignIn.bypass?
      test_user_auth_hash
    else
      request.env["omniauth.auth"]
    end
    core_identity_jwt = auth.extra.raw_info[ONELOGIN_JWT_CORE_IDENTITY_HASH_KEY]
    if core_identity_jwt # available on second call One Login for identity verification
      first_name, surname = extract_name_from_jwt(core_identity_jwt)
      redirect_to(
        claim_path(
          journey: current_journey_routing_name,
          slug: "sign-in",
          claim: {
            identity_confirmed_with_onelogin: true,
            first_name: first_name,
            surname: surname
          }
        )
      )
    else # first call to One Login for authentication
      onelogin_user_info_attributes = auth.info.to_h.slice(
        *SignInForm::OneloginUserInfoForm::ONELOGIN_USER_INFO_ATTRIBUTES.map(&:to_s)
      )

      journey_session.answers.assign_attributes(onelogin_user_info: onelogin_user_info_attributes)
      journey_session.save!

      redirect_to(
        claim_path(
          journey: current_journey_routing_name,
          slug: "sign-in",
          claim: {
            logged_in_with_onelogin: true
          }
        )
      )
    end
  rescue Rack::OAuth2::Client::Error => e
    render plain: e.message
  end

  private

  ONELOGIN_JWT_CORE_IDENTITY_HASH_KEY = "https://vocab.account.gov.uk/v1/coreIdentityJWT"

  def current_journey_routing_name
    if session[:current_journey_routing_name].present?
      session[:current_journey_routing_name]
    else
      # If for some reason the session is empty, redirect the user to the first
      # available user journey
      Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME
    end
  end

  def extract_name_from_jwt(jwt)
    if OneLoginSignIn.bypass?
      first_name = "TEST"
      surname = "USER"
    else
      identity_jwt_public_key = OpenSSL::PKey::EC.new(Base64.decode64(ENV["ONELOGIN_IDENTITY_JWT_PUBLIC_KEY_BASE64"]))
      decoded_jwt = JSON::JWT.decode(jwt, identity_jwt_public_key)
      name_parts = decoded_jwt["vc"]["credentialSubject"]["name"][0]["nameParts"]
      first_name = name_parts.find { |part| part["type"] == "GivenName" }["value"]
      surname = name_parts.find { |part| part["type"] == "FamilyName" }["value"]
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
