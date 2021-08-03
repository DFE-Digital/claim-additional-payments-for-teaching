require "rotp"

module OneTimePassword
  extend ActiveSupport::Concern

  OTP_SECRET = ROTP::Base32.random.freeze
  OTP_PASSWORD_DRIFT = 900
  ONE_TIME_PASSWORD_LENGTH = 6

  private

  def generate_otp
    ROTP::TOTP.new(OTP_SECRET, issuer: "Claim Additional Payments for Teaching").now
  end

  def verify_otp(challenge_code)
    totp = ROTP::TOTP.new(OTP_SECRET, issuer: "Claim Additional Payments for Teaching")
    totp.verify(challenge_code, drift_behind: OTP_PASSWORD_DRIFT)
  end
end
