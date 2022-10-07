module OneTimePassword
  class Validator < Base
    def initialize(code, generated_at, otp_category = nil)
      @code = code
      @generated_at = generated_at
    end

    def valid?
      code.present? && !wrong_length? && !expired? && !incorrect?
    end

    def warning
      return "Enter a passcode" if code.blank?
      return "Enter a valid passcode containing #{LENGTH} digits" if wrong_length?
      return "Your passcode has expired, request a new one" if expired?
      "Enter a valid passcode" if incorrect?
    end

    private

    attr_reader :code, :generated_at, :otp_category

    def wrong_length?
      return @wrong_length if defined?(@wrong_length)

      @wrong_length = code.gsub(/\D/, "").length != LENGTH
    end

    def expired?
      return @expired if defined?(@expired)

      @expired = generated_at < DRIFT.seconds.ago
    end

    def incorrect?
      return @incorrect if defined? @incorrect

      @incorrect = rotp.new(SECRET, issuer: ISSUER).verify(code, drift_behind: DRIFT).nil?
    end
  end
end
