class OneLogin::CoreIdentityValidator
  attr_reader :jwt

  def initialize(jwt:)
    @jwt = jwt
  end

  def call
    JWT.decode(jwt, nil, true, algorithms:, jwks:)
  end

  private

  def algorithms
    OneLogin::DidCache.document.algorithms
  end

  def jwks
    OneLogin::DidCache.document.jwks
  end
end
