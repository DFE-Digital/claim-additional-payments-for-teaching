module OneTimePasswordCheckable
  extend ActiveSupport::Concern

  included do
    attribute :one_time_password, :string, limit: 6
    attribute :sent_one_time_password_at, :datetime
    validate :otp_validate, on: [:"email-verification"]
    before_save :set_sent_one_time_password_at, if: :persisted?
    before_save :normalise_one_time_password, if: :one_time_password_changed?
  end

  private

  def set_sent_one_time_password_at
    self.sent_one_time_password_at = sent_one_time_password_at
  end

  def normalise_one_time_password
    self.one_time_password = one_time_password.gsub(/\D/, "")
  end

  def otp_validate
    return write_attribute(:email_verified, true) if otp.valid?

    errors.add(:one_time_password, otp.warning)
  end

  def otp
    @otp ||= OneTimePassword::Validator.new(one_time_password, set_sent_one_time_password_at)
  end
end
