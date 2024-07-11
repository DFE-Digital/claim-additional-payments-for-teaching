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
    assertion = {
      aud: "https://oidc.integration.account.gov.uk/token", # TODO: use value from discovery
      iss: ENV["ONELOGIN_SIGN_IN_CLIENT_ID"],
      sub: ENV["ONELOGIN_SIGN_IN_CLIENT_ID"],
      exp: 5.minutes.from_now.to_i,
      jti: SecureRandom.uuid, # unique ID
      iat: Time.now.to_i
    }
    private_key = OpenSSL::PKey::RSA.new(Base64.decode64(ENV["ONELOGIN_SIGN_IN_SECRET_BASE64"])) # too clunky? better to read from a file?
    signed_jwt = JWT.encode(assertion, private_key, "RS256")
    # signed_jwt = JSON::JWT.new(assertion).sign(private_key, :RS256) # same as JWT.encode, but has "typ"=>"JWT" in the JWT
    token_request_params = {
      grant_type: "authorization_code",
      code: params["code"],
      redirect_uri: "http://localhost:3000/auth/onelogin", # TODO: get this in the same way config/initializers/omniauth.rb does
      client_assertion_type: "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
      client_assertion: signed_jwt.to_s
    }
    token_response = OpenIDConnect.http_client.post("https://oidc.integration.account.gov.uk/token", token_request_params)
    # results in: {"error_description":"Invalid signature in private_key_jwt","error":"invalid_client"}
    #
    # decode signed JWT using: JWT.decode signed_jwt, private_key.public_key, true, { algorithm: 'RS256' }

    if token_response.code == HTTP::Status::OK
      render plain: "OK"
    else
      # TODO: render :failure, layout: false # check for token_response.code and token_response.error_description\
      render plain: token_response.body
    end
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
