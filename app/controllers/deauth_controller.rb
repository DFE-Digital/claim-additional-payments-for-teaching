class DeauthController < ApplicationController
  include JourneyConcern

  def onelogin
    if ENV["BYPASS_ONELOGIN_SIGN_IN"] == "true"
      redirect_to journey_session.journey_class::SlugSequence.start_page_url
    else
      redirect_to onelogin_redirect_uri, allow_other_host: true
    end

    session.destroy
  end

  def onelogin_callback
    redirect_to Journeys.for_routing_name(params[:state])::SlugSequence.start_page_url
  end

  private

  def onelogin_redirect_uri
    host = ENV["ONELOGIN_SIGN_IN_ISSUER"].split("://")[1].delete("/")
    path = "/logout"
    state = journey::ROUTING_NAME

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
