class DeauthController < ApplicationController
  include JourneyConcern

  def onelogin
    if ENV["BYPASS_ONELOGIN_SIGN_IN"] == "true"
      redirect_to journey_session.journey_class::SlugSequence.signed_out_path
    else
      redirect_to onelogin_redirect_uri, allow_other_host: true
    end

    session.destroy
  end

  def onelogin_callback
    redirect_to Journeys.for_routing_name(params[:state])::SlugSequence.signed_out_path
  end

  def onelogin_back_channel
    return head :bad_request if logout_token.invalid?

    active_sessions = Journeys::Session.where("answers->>'onelogin_uid' = ?", logout_token.user_uid).not_expired
    active_sessions.each(&:expire!)

    head :ok
  rescue => e
    Rollbar.error(e)
    Sentry.capture_exception(e)

    head :bad_request
  end

  private

  def logout_token
    @logout_token ||= OneLogin::LogoutToken.new(jwt: logout_jwt)
  end

  def logout_jwt
    params[:logout_token]
  end

  def onelogin_redirect_uri
    host = ENV["ONELOGIN_SIGN_IN_ISSUER"].split("://")[1].delete("/")
    path = "/logout"
    state = journey.routing_name

    query = [
      "id_token_hint=#{id_token_hint}",
      "post_logout_redirect_uri=#{post_logout_redirect_uri}",
      "state=#{state}"
    ].join("&")

    URI::HTTPS.build(
      host:,
      path:,
      query:
    )
  end

  def id_token_hint
    journey_session.answers.onelogin_credentials["id_token"]
  end

  def post_logout_redirect_uri
    Rails.application.routes.url_helpers.deauth_onelogin_callback_url(
      protocol:,
      host: ENV["CANONICAL_HOSTNAME"]
    )
  end

  def protocol
    if Rails.env.development? || Rails.env.test?
      "http"
    else
      "https"
    end
  end
end
