class EmailAddressForm < Form
  attribute :email_address

  validates :email_address,
    presence: {
      message: ->(form, _) { form.i18n_errors_path("presence") }
    }
  validates :email_address,
    format: {
      with: Rails.application.config.email_regexp,
      message: ->(form, _) { form.i18n_errors_path("format") }
    },
    length: {
      maximum: 256,
      message: ->(form, _) { form.i18n_errors_path("length") }
    },
    if: -> { email_address.present? }

  def save
    return false unless valid?
    return true unless email_address_changed?

    update!(
      email_address: email_address,
      email_verified: email_verified,
      sent_one_time_password_at: Time.now
    )

    ClaimMailer.email_verification(claim, otp_code).deliver_now
  end

  private

  def email_address_changed?
    email_address != claim.email_address
  end

  def email_verified
    return nil if email_address_changed?
    claim.email_verified
  end

  def otp_code
    @otp_code ||= OneTimePassword::Generator.new.code
  end
end
