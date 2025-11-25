class OneLogin::LogoutToken
  attr_reader :jwt

  def initialize(jwt:)
    @jwt = jwt
  end

  def user_uid
    payload[:sub]
  end

  def valid?
    encoded_token.verify_claims!(
      iss:,
      aud:,
      iat: true
    )

    encoded_token.verify!(
      signature: {
        algorithm: ["ES256"],
        key: jwks
      }
    )

    true
  rescue JWT::InvalidIssuerError,
    JWT::InvalidAudError,
    JWT::VerificationError,
    JWT::ExpiredSignature,
    JWT::InvalidIatError => e

    Rollbar.error(e)
    Sentry.capture_exception(e)

    false
  end

  def invalid?
    !valid?
  end

  private

  def encoded_token
    @encoded_token ||= JWT::EncodedToken.new(jwt)
  end

  def iss
    ENV["ONELOGIN_SIGN_IN_ISSUER"]
  end

  def aud
    ENV["ONELOGIN_SIGN_IN_CLIENT_ID"]
  end

  def payload
    decoded_jwt[0]
  end

  def decoded_jwt
    @decoded_jwt ||= JWT.decode(jwt, nil, true, algorithms:, jwks:)
  end

  def algorithms
    OneLogin::DidCache.document.algorithms
  end

  def jwks
    OneLogin::DidCache.document.jwks
  end
end
