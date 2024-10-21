module OneTimePassword
  class Generator < Base
    def initialize(secret:, issuer: nil)
      @issuer = issuer || ISSUER
      @secret = encode_secret(secret) || SECRET
    end

    def code
      @code ||= rotp.new(secret, issuer: issuer).now
    end
  end
end
