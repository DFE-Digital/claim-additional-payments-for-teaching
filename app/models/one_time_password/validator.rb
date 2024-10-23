module OneTimePassword
  class Validator < Base
    def initialize(code, generated_at = nil, secret:)
      @code = code
      @generated_at = generated_at
      @secret = secret
    end

    def valid?
      code.present? && !wrong_length? && (generated_at ? !expired? : true) && !incorrect?
    end

    def warning
      return "Enter a passcode" if code.blank?
      return "Enter a valid passcode containing #{LENGTH} digits" if wrong_length?
      return "Your passcode has expired, request a new one" if expired?
      return "Your passcode is not valid or has expired" if !generated_at && incorrect?
      "Enter a valid passcode" if incorrect?
    end

    private

    attr_reader :code, :generated_at

    def wrong_length?
      return @wrong_length if defined?(@wrong_length)

      @wrong_length = code.length != LENGTH
    end

    def expired?
      return @expired if defined?(@expired)

      @expired = generated_at < DRIFT.seconds.ago if generated_at
    end

    def incorrect?
      return @incorrect if defined? @incorrect

      @incorrect = rotp.new(secret, issuer: ISSUER).verify(code, drift_behind: DRIFT).nil?
    end
  end
end
