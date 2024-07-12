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
    # could be success or failure?
    # TODO: check for error callbacks here

    private_key = OpenSSL::PKey::RSA.new(Base64.decode64(ENV["ONELOGIN_SIGN_IN_SECRET_BASE64"] + "\n")) # too clunky? better to read from a file?

    discover = OpenIDConnect::Discovery::Provider::Config.discover! ENV["ONELOGIN_SIGN_IN_ISSUER"]
    client = OpenIDConnect::Client.new(
      identifier: ENV["ONELOGIN_SIGN_IN_CLIENT_ID"],
      private_key: private_key,
      redirect_uri: "#{ENV["ONELOGIN_REDIRECT_BASE_URL"]}/auth/onelogin",
      authorization_endpoint: discover.authorization_endpoint,
      token_endpoint: discover.token_endpoint,
      userinfo_endpoint: discover.userinfo_endpoint
    )
    client.authorization_code = params["code"]
    access_token = client.access_token!(client_auth_method: :jwt_bearer, grant_type: "authorization_code")

    render plain: "access_token: #{access_token}"
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
