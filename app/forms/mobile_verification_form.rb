class MobileVerificationForm < Form
  attribute :one_time_password

  # Required for shared partial in the view
  delegate :mobile_number, to: :claim

  validate :otp_validate

  before_validation do
    self.one_time_password = one_time_password.gsub(/\D/, "")
  end

  def save
    return false unless valid?

    update!(mobile_verified: true)
  end

  private

  def otp_validate
    otp = OneTimePassword::Validator.new(
      one_time_password,
      claim.sent_one_time_password_at
    )

    errors.add(:one_time_password, otp.warning) unless otp.valid?
  end
end
