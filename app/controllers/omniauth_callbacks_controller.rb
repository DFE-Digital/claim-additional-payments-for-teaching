class OmniauthCallbacksController < ApplicationController
  include JourneyConcern

  ONELOGIN_JWT_CORE_IDENTITY_HASH_KEY = "https://vocab.account.gov.uk/v1/coreIdentityJWT".freeze

  def callback
    auth = request.env["omniauth.auth"]

    case params[:journey]
    when "further-education-payments-provider"
      further_education_payments_provider_callback(auth)
    else
      # The callback route for student loans and additional payments isn't
      # namespaced under a journey
      additional_payments_callback(auth)
    end
  end

  def failure
    case params[:strategy]
    when "onelogin"
      render OneLogin::FailureHandler.new(
        message: params[:message],
        origin: params[:origin],
        answers: journey_session&.answers
      ).template
    else
      render :dfe_identity_failure
    end
  end

  def sign_out
    case current_journey_routing_name
    when "further-education-payments-provider"
      claim = journey_session.answers.claim
      clear_journey_sessions!

      flash[:success] = "You have signed out of DfE Sign-in"
      redirect_to(
        Journeys::FurtherEducationPayments::Provider::SlugSequence.verify_claim_url(claim)
      )
    else
      render file: Rails.root.join("public", "404.html"), status: :not_found, layout: false
    end
  end

  def onelogin
    core_identity_jwt = omniauth_hash.extra.raw_info[ONELOGIN_JWT_CORE_IDENTITY_HASH_KEY]
    return process_one_login_identity_verification_callback(core_identity_jwt) if core_identity_jwt
    process_one_login_authentication_callback
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

  def process_one_login_authentication_callback
    onelogin_user_info = omniauth_hash.info.to_h.slice("email", "phone")
    onelogin_credentials = omniauth_hash.credentials

    journey_session.answers.assign_attributes(
      onelogin_uid: omniauth_hash.uid,
      onelogin_user_info:,
      onelogin_credentials:,
      onelogin_auth_at: Time.now,
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
    if omniauth_hash.uid != journey_session.answers.onelogin_uid
      origin = claim_url(
        journey: current_journey_routing_name,
        slug: "sign-in"
      )
      return redirect_to "/auth/failure?strategy=onelogin&message=access_denied&origin=#{origin}"
    end

    first_name, last_name, full_name, date_of_birth = extract_data_from_jwt(core_identity_jwt)

    journey_session.answers.assign_attributes(
      identity_confirmed_with_onelogin: true,
      onelogin_idv_at: Time.now,
      onelogin_idv_first_name: first_name,
      onelogin_idv_last_name: last_name,
      onelogin_idv_full_name: full_name,
      onelogin_idv_date_of_birth: date_of_birth
    )
    journey_session.answers.first_name ||= first_name
    journey_session.answers.surname ||= last_name
    journey_session.answers.date_of_birth ||= date_of_birth
    journey_session.save!

    redirect_to(
      claim_path(
        journey: current_journey_routing_name,
        slug: "sign-in"
      )
    )
  end

  ONE_LOGIN_TEST_USER = {
    first_name: "TEST",
    last_name: "USER",
    date_of_birth: Date.new(1970, 1, 1)
  }

  def extract_data_from_jwt(jwt)
    if OneLoginSignIn.bypass?
      first_name = ONE_LOGIN_TEST_USER[:first_name]
      last_name = ONE_LOGIN_TEST_USER[:last_name]
      full_name = "#{first_name} #{last_name}"
      date_of_birth = ONE_LOGIN_TEST_USER[:date_of_birth]
    else
      validator = OneLogin::CoreIdentityValidator.new(jwt:)
      validator.call
      first_name = validator.first_name
      last_name = validator.last_name
      full_name = validator.full_name
      date_of_birth = validator.date_of_birth
    end

    [first_name, last_name, full_name, date_of_birth]
  end

  def test_user_auth_hash
    if request.path == "/auth/onelogin"
      OmniAuth::AuthHash.new(uid: "12345", info: {email: "test@example.com"}, extra: {raw_info: {}})
    elsif request.path == "/auth/onelogin_identity"
      OmniAuth::AuthHash.new(uid: "12345", info: {email: ""}, extra: {raw_info: {ONELOGIN_JWT_CORE_IDENTITY_HASH_KEY => "test"}})
    end
  end

  def omniauth_hash
    @omniauth_hash ||= if OneLoginSignIn.bypass?
      test_user_auth_hash
    else
      request.env["omniauth.auth"]
    end
  end

  def further_education_payments_provider_callback(auth)
    auth = params if DfESignIn.bypass?

    Journeys::FurtherEducationPayments::Provider::OmniauthCallbackForm.new(
      journey_session: journey_session,
      auth: auth
    ).save!

    session[:slugs] << "sign-in"

    redirect_to(
      claim_path(
        journey: current_journey_routing_name,
        slug: "verify-claim"
      )
    )
  end

  def additional_payments_callback(auth)
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
end
