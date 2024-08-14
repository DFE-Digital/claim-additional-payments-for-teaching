class OneLogin::Did
  attr_reader :document_hash

  def initialize(document_hash:)
    @document_hash = document_hash
  end

  def context
    document_hash["@context"]
  end

  def id
    document_hash["id"]
  end

  def assertion_methods
    document_hash["assertionMethod"]
  end
end
