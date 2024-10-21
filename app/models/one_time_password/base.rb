require "rotp"

module OneTimePassword
  class Base
    DRIFT = 900
    LENGTH = 6
    ISSUER = "Claim Additional Payments for Teaching"
    SECRET = ROTP::Base32.random.freeze

    def rotp
      @rotp ||= ROTP::TOTP
    end

    private

    attr_reader :issuer, :secret

    def encode_secret(secret)
      ROTP::Base32.encode(secret) if secret
    end
  end
end
