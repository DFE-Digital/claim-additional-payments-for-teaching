# frozen_string_literal: true

OmniAuth.configure do |config|
  config.logger = Rails.logger
end

dfe_sign_in_issuer = ENV["DFE_SIGN_IN_ISSUER"]
dfe_sign_in_redirect_base_url = ENV["DFE_SIGN_IN_REDIRECT_BASE_URL"]
dfe_sign_in_identifier = ENV["DFE_SIGN_IN_IDENTIFIER"]
dfe_sign_in_secret = ENV["DFE_SIGN_IN_SECRET"]

dfe_sign_in_issuer_uri = dfe_sign_in_issuer.present? ? URI(dfe_sign_in_issuer) : nil
dfe_sign_in_redirect_uri = if dfe_sign_in_redirect_base_url.present?
  URI.join(dfe_sign_in_redirect_base_url,
    "/admin/auth/callback")
end

dfe_options = {
  name: :dfe,
  discovery: true,
  response_type: :code,
  scope: %i[openid email organisation],
  callback_path: "/admin/auth/callback",
  client_options: {
    port: dfe_sign_in_issuer_uri&.port,
    scheme: dfe_sign_in_issuer_uri&.scheme,
    host: dfe_sign_in_issuer_uri&.host,
    identifier: dfe_sign_in_identifier,
    secret: dfe_sign_in_secret,
    redirect_uri: dfe_sign_in_redirect_uri&.to_s
  },
  issuer:
    ("#{dfe_sign_in_issuer_uri}:#{dfe_sign_in_issuer_uri.port}" if dfe_sign_in_issuer_uri.present?)
}

tid_sign_issuer = ENV["TID_SIGN_IN_ISSUER"]
tid_sign_in_secret = ENV["TID_SIGN_IN_SECRET"]
tid_sign_in_endpoint = ENV["TID_SIGN_IN_API_ENDPOINT"]
tid_base_url = ENV["TID_BASE_URL"]

tid_sign_in_endpoint_uri = tid_sign_in_endpoint.present? ? URI(tid_sign_in_endpoint) : nil

tid_sign_in_redirect_uri = tid_base_url.present? ? URI.join(tid_base_url, "/claim/auth/tid/callback").to_s : nil

tid_options = {
  name: :tid,
  provider_ignores_state: true,
  allow_authorize_params: %i[session_id trn_token],
  callback_path: "/claim/auth/tid/callback",
  client_options: {
    host: tid_sign_in_endpoint_uri&.host,
    identifier: ENV["TID_SIGN_IN_CLIENT_ID"],
    port: tid_sign_in_endpoint_uri&.port,
    redirect_uri: tid_sign_in_redirect_uri,
    scheme: tid_sign_in_endpoint_uri&.scheme || "https",
    secret: tid_sign_in_secret
  },
  discovery: true,
  issuer: tid_sign_issuer,
  pkce: true,
  response_type: :code,
  scope: ["email", "openid", "profile", "dqt:read"]
}

module ::DfESignIn
  def self.bypass?
    (Rails.env.development? || ENV["ENVIRONMENT_NAME"] == "review") && ENV["BYPASS_DFE_SIGN_IN"] == "true"
  end
end


Rails.application.config.middleware.use OmniAuth::Builder do
  if DfESignIn.bypass?
    provider :developer
  else
    provider :openid_connect, dfe_options
  end

  provider :openid_connect, tid_options
end
