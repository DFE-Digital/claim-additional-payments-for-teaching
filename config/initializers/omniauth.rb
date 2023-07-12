OmniAuth.configure do |config|
  config.logger = Rails.logger
  config.path_prefix = "/admin/auth"
end

dfe_sign_in_issuer = ENV["DFE_SIGN_IN_ISSUER"]
dfe_sign_in_redirect_base_url = ENV["DFE_SIGN_IN_REDIRECT_BASE_URL"]
dfe_sign_in_identifier = ENV["DFE_SIGN_IN_IDENTIFIER"]
dfe_sign_in_secret = ENV["DFE_SIGN_IN_SECRET"]

dfe_sign_in_issuer_uri = dfe_sign_in_issuer.present? ? URI(dfe_sign_in_issuer) : nil
dfe_sign_in_redirect_uri = dfe_sign_in_redirect_base_url.present? ? URI.join(dfe_sign_in_redirect_base_url, "/admin/auth/callback") : nil

options = {
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

module ::DfESignIn
  def self.bypass?
    (Rails.env.development? || ENV["ENVIRONMENT_NAME"] == "review") && ENV["BYPASS_DFE_SIGN_IN"] == "true"
  end
end

if DfESignIn.bypass?
  Rails.application.config.middleware.use OmniAuth::Builder do
    provider :developer
  end
else
  Rails.application.config.middleware.use OmniAuth::Strategies::OpenIDConnect, options
end
