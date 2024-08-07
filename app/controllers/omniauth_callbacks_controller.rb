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

  # Prob better to update the `callback` method to check the journey rather
  # than a separate method, maybe a callback form for each journey?
  def further_education_payments_provider
    # Not stoked on updating a record in a get request!
    # Ideally we'd cache these in session then write them to the record after
    # posting a form

    organisation_id = request.env["omniauth.auth"].extra.raw_info.organisation.id
    organisation_ukprn = request.env["omniauth.auth"].extra.raw_info.organisation.ukprn
    uid = request.env["omniauth.auth"].uid

    dfe_sign_in_user = DfeSignIn::Api::User.new(
      user_id: uid,
      organisation_id: organisation_id
    )

    journey_session.answers.assign_attributes(
      dfe_sign_in_uid: uid,
      dfe_sign_in_organisation_ukprn: organisation_ukprn,
      dfe_sign_in_organisation_role_codes: dfe_sign_in_user.role_codes
    )

    journey_session.save!

    # Yeah this should be a form object

    authorisation = journey::Authorisation.new(
      answers: journey_session.answers,
      slug: "verify-claim"
    )

    session[:slugs] << "sign-in"

    if authorisation.authorised?
      redirect_to(
        claim_path(journey: current_journey_routing_name, slug: "verify-claim")
      )
    else
      puts "in auth faliure"
      redirect_to(
        claim_path(
          journey: current_journey_routing_name,
          slug: "authorisation-failure",
          reason: authorisation.failure_reason
        )
      )
    end

    # FIXME handle errors, eg "omniauth hash not being present"
    # Think this should be handled by a form
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
    return process_one_login_identity_verification_callback(core_identity_jwt) if core_identity_jwt
    process_one_login_authentication_callback(auth)
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

  def process_one_login_authentication_callback(auth)
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

  def process_one_login_identity_verification_callback(core_identity_jwt)
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
