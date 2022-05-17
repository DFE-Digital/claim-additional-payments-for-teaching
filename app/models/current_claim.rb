class CurrentClaim
  attr_reader :claims

  def initialize(claims:)
    @claims = claims
  end

  def main_claim
    claims.first
  end

  # method_missing does not catch this
  def to_param
    main_claim.to_param
  end

  def method_missing(method_name, *args, &block)
    Rails.logger.info("======<CurrentClaim#method_missing>======")
    Rails.logger.info(method_name.inspect)
    result = main_claim.send(method_name, *args, &block)
    Rails.logger.info(result.inspect)
    Rails.logger.info("======<END>==============================")
    result
  end

  def respond_to_missing?(method_name, *args)
    main_claim.respond_to?(method_name, *args)
  end
end
