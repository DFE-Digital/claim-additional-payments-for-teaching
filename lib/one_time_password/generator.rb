module OneTimePassword
  class Generator < Base
    def initialize(issuer = nil)
      @issuer = issuer || ISSUER
    end

    def code
      @code ||= rotp.new(SECRET, issuer: issuer).now
    end
  end
end
