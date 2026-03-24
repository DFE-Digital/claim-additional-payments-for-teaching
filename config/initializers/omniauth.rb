# frozen_string_literal: true

OmniAuth.configure do |config|
  config.logger = Rails.logger
end

OmniAuth.config.on_failure = proc { |env|
  # redirects to `/auth/failure`, check routes.rb
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
}

Rails.application.config.middleware.use OmniAuth::Builder do
  # https://preprod.authorise-access-to-a-teaching-record.education.gov.uk/.well-known/openid-configuration
  provider :openid_connect, {
    name: :teacher,
    discovery: true,
    response_type: :code,
    # scope: %i[openid email profile offline_access teaching_record],
    scope: %i[openid email teaching_record],
    send_scope_to_token_endpoint: false,
    callback_path: "/early-years-teachers-financial-incentive-payments/auth/teacher/callback",
    path_prefix: "/early-years-teachers-financial-incentive-payments/auth",
    issuer: "https://preprod.authorise-access-to-a-teaching-record.education.gov.uk/",
    pkce: true,
    client_options: {
      port: 443,
      scheme: "https",
      host: "preprod.authorise-access-to-a-teaching-record.education.gov.uk",
      identifier: ENV["TEACHER_AUTH_CLIENT_ID"],
      secret: ENV["TEACHER_AUTH_SECRET"],
      redirect_uri: "http://localhost:3000/early-years-teachers-financial-incentive-payments/auth/teacher/callback",

      authorization_endpoint: "/oauth2/authorize",
      end_session_endpoint: "/oauth2/logout",
      token_endpoint: "/oauth2/token",
      userinfo_endpoint: "/oauth2/userinfo",
      jwks_uri: "https://preprod.authorise-access-to-a-teaching-record.education.gov.uk/.well-known/jwks",
    },
  }

  # if DfeSignIn::Config.instance.bypass?
  #   provider :developer
  # else
  #   provider :openid_connect, {
  #     name: :dfe,
  #     discovery: true,
  #     response_type: :code,
  #     scope: %i[openid email organisation],
  #     callback_path: "/admin/auth/callback",
  #     path_prefix: "/admin/auth",
  #     client_options: {
  #       port: DfeSignIn::Config.instance.issuer_uri&.port,
  #       scheme: DfeSignIn::Config.instance.issuer_uri&.scheme,
  #       host: DfeSignIn::Config.instance.issuer_uri&.host,
  #       identifier: ENV["DFE_SIGN_IN_INTERNAL_CLIENT_ID"],
  #       secret: ENV["DFE_SIGN_IN_INTERNAL_CLIENT_SECRET"],
  #       redirect_uri: DfeSignIn::Config.instance.redirect_uri&.to_s
  #     },
  #     issuer:
  #       ("#{DfeSignIn::Config.instance.issuer_uri}:#{DfeSignIn::Config.instance.issuer_uri.port}" if DfeSignIn::Config.instance.issuer_uri.present?)
  #   }

  #   provider :openid_connect, {
  #     name: :dfe_fe_provider,
  #     discovery: true,
  #     response_type: :code,
  #     scope: %i[openid email organisation first_name last_name],
  #     callback_path: DfeSignIn::Config.instance.fe_provider_callback_path,
  #     path_prefix: "/further-education-payments-provider/auth",
  #     client_options: {
  #       port: DfeSignIn::Config.instance.issuer_uri&.port,
  #       scheme: DfeSignIn::Config.instance.issuer_uri&.scheme,
  #       host: DfeSignIn::Config.instance.issuer_uri&.host,
  #       identifier: ENV["DFE_SIGN_IN_IDENTIFIER"],
  #       secret: ENV["DFE_SIGN_IN_SECRET"],
  #       redirect_uri: DfeSignIn::Config.instance.fe_provider_redirect_uri&.to_s
  #     },
  #     issuer:
  #       ("#{DfeSignIn::Config.instance.issuer_uri}:#{DfeSignIn::Config.instance.issuer_uri.port}" if DfeSignIn::Config.instance.issuer_uri.present?)
  #   }
  # end

  # provider :openid_connect, {
  #   name: :tid,
  #   callback_path: "/claim/auth/tid/callback",
  #   client_options: {
  #     host: TeacherId::Config.instance.sign_in_endpoint_uri&.host,
  #     identifier: ENV["TID_SIGN_IN_CLIENT_ID"],
  #     port: TeacherId::Config.instance.sign_in_endpoint_uri&.port,
  #     redirect_uri: TeacherId::Config.instance.sign_in_redirect_uri&.to_s,
  #     scheme: TeacherId::Config.instance.sign_in_endpoint_uri&.scheme || "https",
  #     secret: ENV["TID_SIGN_IN_SECRET"]
  #   },
  #   discovery: true,
  #   issuer: ENV["TID_SIGN_IN_ISSUER"],
  #   pkce: true,
  #   scope: ["email", "openid", "profile", "dqt:read"],
  #   send_scope_to_token_endpoint: false
  # }

  # if OneLogin::Config.instance.bypass?
  #   provider :developer
  # else
  #   provider :openid_connect, {
  #     name: :onelogin,
  #     callback_path: "/auth/onelogin",
  #     client_auth_method: "jwt_bearer",
  #     client_options: {
  #       host: OneLogin::Config.instance.issuer_uri&.host,
  #       identifier: ENV["ONELOGIN_SIGN_IN_CLIENT_ID"],
  #       port: OneLogin::Config.instance.issuer_uri&.port,
  #       redirect_uri: OneLogin::Config.instance.redirect_uri&.to_s,
  #       scheme: OneLogin::Config.instance.issuer_uri&.scheme,
  #       secret: OneLogin::Config.instance.secret_key
  #     },
  #     discovery: true,
  #     issuer: ENV["ONELOGIN_SIGN_IN_ISSUER"],
  #     response_type: :code,
  #     scope: %i[openid email phone],
  #     send_scope_to_token_endpoint: false
  #   }

  #   provider :openid_connect, {
  #     name: :onelogin_identity,
  #     callback_path: "/auth/onelogin_identity",
  #     client_options: {
  #       host: OneLogin::Config.instance.issuer_uri&.host,
  #       identifier: ENV["ONELOGIN_SIGN_IN_CLIENT_ID"],
  #       port: OneLogin::Config.instance.issuer_uri&.port,
  #       redirect_uri: OneLogin::Config.instance.redirect_uri&.to_s,
  #       scheme: OneLogin::Config.instance.issuer_uri&.scheme
  #     },
  #     discovery: true,
  #     extra_authorize_params: {
  #       vtr: '["Cl.Cm.P2"]',
  #       claims: {userinfo: {"https://vocab.account.gov.uk/v1/coreIdentityJWT": nil, "https://vocab.account.gov.uk/v1/returnCode": nil}}.to_json
  #     },
  #     issuer: ENV["ONELOGIN_SIGN_IN_ISSUER"],
  #     response_type: :code,
  #     send_scope_to_token_endpoint: false
  #   }
  # end
end
