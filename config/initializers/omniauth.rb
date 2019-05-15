OmniAuth.config.logger = Rails.logger

dfe_sign_in_issuer_uri    = URI(ENV.fetch("DFE_SIGN_IN_ISSUER"))
dfe_sign_in_identifier    = ENV.fetch("DFE_SIGN_IN_IDENTIFIER")
dfe_sign_in_secret        = ENV.fetch("DFE_SIGN_IN_SECRET")
dfe_sign_in_redirect_uri  = ENV.fetch("DFE_SIGN_IN_REDIRECT_URL")

options = {
  name: :dfe,
  discovery: true,
  response_type: :code,
  scope: %i[openid email organisation],
  callback_path: "/auth/callback",
  client_options: {
    port: dfe_sign_in_issuer_uri.port,
    scheme: dfe_sign_in_issuer_uri.scheme,
    host: dfe_sign_in_issuer_uri.host,
    identifier: dfe_sign_in_identifier,
    secret: dfe_sign_in_secret,
    redirect_uri: dfe_sign_in_redirect_uri,
  },
}

Rails.application.config.middleware.use OmniAuth::Strategies::OpenIDConnect, options
