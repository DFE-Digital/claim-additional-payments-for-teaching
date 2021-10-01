module OneTimePasswordCheckable
  extend ActiveSupport::Concern

  CATEGORIES = %w[
    claim_email
    claim_mobile
    reminder_email
  ].freeze

  included do
    attribute :one_time_password, :string, limit: 6
    attribute :one_time_password_category, :string
    attribute :sent_one_time_password_at, :datetime
    validate :otp_validate, on: [:"email-verification", :"mobile-verification"]
    before_save :normalise_one_time_password, if: :one_time_password_changed?
  end

  private

  def normalise_one_time_password
    self.one_time_password = one_time_password.gsub(/\D/, "")
  end

  def otp_validate
    return unless CATEGORIES.include?(one_time_password_category)
    return write_attribute(:email_verified, true) if otp.valid? && %w[claim_email reminder_email].include?(one_time_password_category)
    return write_attribute(:mobile_verified, true) if otp.valid? && one_time_password_category == "claim_mobile"

    errors.add(:one_time_password, otp.warning)
  end

  def otp
    @otp ||= OneTimePassword::Validator.new(one_time_password, sent_one_time_password_at, one_time_password_category)
  end
end
