class MobileVerificationForm < Form
  attribute :one_time_password

  # Required for shared partial in the view
  delegate :mobile_number, to: :answers

  validate :otp_validate

  before_validation do
    self.one_time_password = (one_time_password || "").gsub(/\D/, "")
  end

  def save
    return false unless valid?

    journey_session.answers.update!(mobile_verified: true)
  end

  def completed?
    journey_session.answers.mobile_verified?
  end

  private

  def otp_validate
    otp = OneTimePassword::Validator.new(
      one_time_password,
      answers.sent_one_time_password_at,
      secret: journey_session.answers.mobile_verification_secret
    )

    errors.add(:one_time_password, otp.warning) unless otp.valid?
  end
end
