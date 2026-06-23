class SupportAgentPolicy
  attr_reader :admin, :claim

  def initialize(admin, claim)
    @admin = admin
    @claim = claim
  end
end
