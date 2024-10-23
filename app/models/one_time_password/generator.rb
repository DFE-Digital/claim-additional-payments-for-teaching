module OneTimePassword
  class Generator < Base
    def initialize(secret:, issuer: nil)
      @issuer = issuer || ISSUER
      @secret = secret
    end

    def code
      @code ||= rotp.new(secret, issuer: issuer).now
    end
  end
end
