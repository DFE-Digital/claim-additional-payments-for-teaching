class EmailAddressForm < Form
  attribute :email_address

  validates :email_address, presence: {message: "Enter an email address"} # TODO RL: i18n
  validates :email_address,
    format: {
      with: Rails.application.config.email_regexp,
      message: "Enter an email address in the correct format, like name@example.com"
    },
    length: {
      maximum: 256,
      message: "Email address must be 256 characters or less"
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
