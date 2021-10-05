module OneTimePassword
  class Validator < Base
    def initialize(code, generated_at, otp_category = nil)
      @code = code
      @generated_at = generated_at
      @otp_category = otp_category
    end

    def valid?
      code.present? && !wrong_length? && !expired? && !incorrect?
    end

    def warning
      return "Enter your one time password" if code.blank?
      return "Your one time password must be #{LENGTH}-digits" if wrong_length?
      return "Your one time password has expired, request a new one" if expired?
      "Enter the correct one time password that we #{delivery_method_text}" if incorrect?
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

    def delivery_method_text
      return "sent to you in a text message" if otp_category == "claim_mobile"
      "emailed to you" if otp_category == "claim_email" || otp_category.nil?
    end
  end
end
