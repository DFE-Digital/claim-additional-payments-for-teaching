class OneLogin::CoreIdentityValidator
  attr_reader :jwt, :decoded_jwt

  def initialize(jwt:)
    @jwt = jwt
  end

  def call
    @decoded_jwt ||= JWT.decode(jwt, nil, true, algorithms:, jwks:)
  end

  def first_name
    name_parts.find { |part| part["type"] == "GivenName" }["value"]
  end

  def last_name
    name_parts.find { |part| part["type"] == "FamilyName" }["value"]
  end

  def date_of_birth
    Date.parse(decoded_jwt[0]["vc"]["credentialSubject"]["birthDate"][0]["value"])
  end

  def full_name
    given_names = name_parts
      .select { |hash| hash["type"] == "GivenName" }
      .map { |hash| hash["value"] }

    family_names = name_parts
      .select { |hash| hash["type"] == "FamilyName" }
      .map { |hash| hash["value"] }

    (given_names + family_names).join(" ")
  end

  private

  def name_parts
    decoded_jwt[0]["vc"]["credentialSubject"]["name"][0]["nameParts"]
  end

  def algorithms
    OneLogin::DidCache.document.algorithms
  end

  def jwks
    OneLogin::DidCache.document.jwks
  end
end
