class OneLogin::LogoutToken
  attr_reader :jwt

  def initialize(jwt:)
    @jwt = jwt
  end

  def user_uid
    payload[:sub]
  end

  private

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
