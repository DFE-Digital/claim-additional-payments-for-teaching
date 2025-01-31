class EmailAddressForm < Form
  attribute :email_address
  attribute :resend, :boolean

  validates :email_address,
    presence: {
      message: ->(form, _) { form.i18n_errors_path("presence") }
    }
  validates :email_address,
    email_address_format: {
      message: ->(form, _) { form.i18n_errors_path("format") }
    },
    length: {
      maximum: Rails.application.config.email_max_length,
      message: ->(form, _) { form.i18n_errors_path("length", length: Rails.application.config.email_max_length) }
    },
    if: -> { email_address.present? }

  def save
    return false unless valid?
    return true unless email_address_changed? || resend

    journey_session.answers.assign_attributes(
      email_address: email_address,
      email_verified: email_verified,
      email_verification_secret: otp_secret,
      sent_one_time_password_at: Time.now
    )

    journey_session.save!

    ClaimMailer.email_verification(answers, otp_code, journey_session.journey_class.journey_name).deliver_now
  end

  private

  def email_address_changed?
    email_address != answers.email_address
  end

  def email_verified
    return nil if email_address_changed?
    answers.email_verified
  end

  def otp_secret
    @otp_secret ||= ROTP::Base32.random
  end

  def otp_code
    @otp_code ||= OneTimePassword::Generator.new(secret: otp_secret).code
  end
end
