module OneTimePassword
  class Generator < Base
    def initialize(issuer:)
      @issuer = issuer || ISSUER
    end

    def code
      @code ||= rotp.new(SECRET, issuer: issuer).now
    end
  end
end
