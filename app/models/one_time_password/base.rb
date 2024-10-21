require "rotp"

module OneTimePassword
  class Base
    DRIFT = 900
    LENGTH = 6
    ISSUER = "Claim Additional Payments for Teaching"

    def rotp
      @rotp ||= ROTP::TOTP
    end

    private

    attr_reader :issuer, :secret
  end
end
