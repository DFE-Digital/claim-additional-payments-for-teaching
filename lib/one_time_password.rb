require "rotp"

module OneTimePassword
  extend ActiveSupport::Concern

  OTP_SECRET = ROTP::Base32.random.freeze
  OTP_PASSWORD_INTERVAL = 900
  ONE_TIME_PASSWORD_LENGTH = 6

  private

  def generate_otp
    ROTP::TOTP.new(OTP_SECRET, issuer: "Claim Additional Payments for Teaching", interval: OTP_PASSWORD_INTERVAL).now
  end

  def verify_otp(challenge_code)
    totp = ROTP::TOTP.new(OTP_SECRET, issuer: "Claim Additional Payments for Teaching", interval: OTP_PASSWORD_INTERVAL)
    totp.verify(challenge_code)
  end
end
