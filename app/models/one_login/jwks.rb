class OneLogin::Jwks
  attr_reader :document_hash

  def initialize(document_hash:)
    @document_hash = document_hash
  end

  def algorithms
    @algorithms ||= keys.map do |key|
      key.dig("alg")
    end.uniq
  end

  def jwks
    return @jwks if @jwks

    jwk_objects = keys.map do |key|
      JWT::JWK.new(key)
    end

    @jwks = JWT::JWK::Set.new(jwk_objects)
  end

  private

  def keys
    @keys ||= document_hash["keys"]
  end
end
