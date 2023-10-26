# frozen_string_literal: true

OmniAuth.configure do |config|
  config.logger = Rails.logger
end

dfe_sign_in_issuer_uri = ENV["DFE_SIGN_IN_ISSUER"].present? ? URI(ENV["DFE_SIGN_IN_ISSUER"]) : nil

if ENV["DFE_SIGN_IN_REDIRECT_BASE_URL"].present?
  dfe_sign_in_redirect_uri = URI.join(ENV["DFE_SIGN_IN_REDIRECT_BASE_URL"], "/admin/auth/callback")
end

tid_sign_in_endpoint_uri = ENV["TID_SIGN_IN_API_ENDPOINT"].present? ? URI(ENV["TID_SIGN_IN_API_ENDPOINT"]) : nil

if ENV["TID_BASE_URL"].present?
  tid_sign_in_redirect_uri = URI.parse(ENV["TID_BASE_URL"])
  tid_sign_in_redirect_uri.path = "/claim/auth/tid/callback"

  if ENV["ENVIRONMENT_NAME"] == "review"
    tid_sign_in_redirect_uri.host = ENV["CANONICAL_HOSTNAME"]
  end
end

module ::DfESignIn
  def self.bypass?
    (Rails.env.development? || ENV["ENVIRONMENT_NAME"] == "review") && ENV["BYPASS_DFE_SIGN_IN"] == "true"
  end
end

Rails.application.config.middleware.use OmniAuth::Builder do
  if DfESignIn.bypass?
    provider :developer
  else
    provider :openid_connect, {
      name: :dfe,
      discovery: true,
      response_type: :code,
      scope: %i[openid email organisation],
      callback_path: "/admin/auth/callback",
      path_prefix: "/admin/auth",
      client_options: {
        port: dfe_sign_in_issuer_uri&.port,
        scheme: dfe_sign_in_issuer_uri&.scheme,
        host: dfe_sign_in_issuer_uri&.host,
        identifier: ENV["DFE_SIGN_IN_IDENTIFIER"],
        secret: ENV["DFE_SIGN_IN_SECRET"],
        redirect_uri: dfe_sign_in_redirect_uri&.to_s
      },
      issuer:
        ("#{dfe_sign_in_issuer_uri}:#{dfe_sign_in_issuer_uri.port}" if dfe_sign_in_issuer_uri.present?)
    }
  end

  provider :openid_connect, {
    name: :tid,
    provider_ignores_state: true,
    allow_authorize_params: %i[session_id trn_token],
    callback_path: "/claim/auth/tid/callback",
    client_options: {
      host: tid_sign_in_endpoint_uri&.host,
      identifier: ENV["TID_SIGN_IN_CLIENT_ID"],
      port: tid_sign_in_endpoint_uri&.port,
      redirect_uri: tid_sign_in_redirect_uri&.to_s,
      scheme: tid_sign_in_endpoint_uri&.scheme || "https",
      secret: ENV["TID_SIGN_IN_SECRET"]
    },
    discovery: true,
    issuer: ENV["TID_SIGN_IN_ISSUER"],
    pkce: true,
    response_type: :code,
    scope: ["email", "openid", "profile", "dqt:read"],
    send_scope_to_token_endpoint: false
  }
end
