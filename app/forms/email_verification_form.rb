class EmailVerificationForm < Form
  attribute :one_time_password

  # Required for shared partial in the view
  delegate :email_address, to: :claim

  validate :otp_validate

  before_validation do
    self.one_time_password = one_time_password.gsub(/\D/, "")
  end

  def save
    return false unless valid?

    update!(email_verified: true)
  end

  private

  def sent_one_time_password_at
    claim.sent_one_time_password_at
  end

  def otp_validate
    otp = OneTimePassword::Validator.new(
      one_time_password,
      sent_one_time_password_at
    )

    errors.add(:one_time_password, otp.warning) unless otp.valid?
  end
end
