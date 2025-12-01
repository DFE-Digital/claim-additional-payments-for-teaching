class OneLogin::Did
  attr_reader :document_hash

  def initialize(document_hash:)
    @document_hash = document_hash
  end

  def context
    @context ||= document_hash["@context"]
  end

  def id
    @id ||= document_hash["id"]
  end

  def assertion_methods
    @assertion_methods ||= document_hash["assertionMethod"]
  end

  def algorithms
    @algorithms ||= assertion_methods.map do |assertion|
      assertion.dig("publicKeyJwk", "alg")
    end.uniq
  end

  def jwks
    return @jwks if @jwks

    keys = assertion_methods.map do |assertion|
      jwk = JWT::JWK.new(assertion["publicKeyJwk"])
      jwk[:kid] = assertion["id"]
      jwk
    end

    @jwks = JWT::JWK::Set.new(keys)
  end
end
