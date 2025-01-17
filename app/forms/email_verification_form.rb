class EmailVerificationForm < Form
  attribute :one_time_password

  # Required for shared partial in the view
  delegate :email_address, to: :answers

  validate :sent_one_time_password_must_be_valid
  validate :otp_must_be_valid, if: :sent_one_time_password_at?

  before_validation do
    self.one_time_password = (one_time_password || "").gsub(/\D/, "")
  end

  def save
    return false unless valid?

    journey_session.answers.assign_attributes(email_verified: true)
    journey_session.save!
  end

  private

  def sent_one_time_password_at
    answers.sent_one_time_password_at
  end

  def sent_one_time_password_must_be_valid
    return if sent_one_time_password_at?

    errors.add(:one_time_password, i18n_errors_path(:"one_time_password.invalid"))
  end

  def otp_must_be_valid
    otp = OneTimePassword::Validator.new(
      one_time_password,
      sent_one_time_password_at,
      secret: journey_session.answers.email_verification_secret
    )

    errors.add(:one_time_password, otp.warning) unless otp.valid?
  end

  def sent_one_time_password_at?
    sent_one_time_password_at&.to_datetime || false
  rescue Date::Error
    false
  end
end
