class MobileNumberForm < Form
  attribute :mobile_number

  validates :mobile_number,
    presence: {
      message: ->(form, _) { form.i18n_errors_path("invalid") }
    }

  validates :mobile_number,
    format: {
      with: /\A(\+44\s?)?(?:\d\s?){10,11}\z/,
      message: ->(form, _) { form.i18n_errors_path("invalid") }
    },
    if: -> { mobile_number.present? }

  def save
    return false unless valid?
    return true unless mobile_number_changed?

    sent_one_time_password_at = if send_sms_message
      Time.now
    end

    journey_session.answers.assign_attributes(
      mobile_number: mobile_number,
      mobile_verified: nil,
      sent_one_time_password_at: sent_one_time_password_at
    )

    journey_session.save!
  end

  private

  def send_sms_message
    NotifySmsMessage.new(
      phone_number: mobile_number,
      template_id: NotifySmsMessage::OTP_PROMPT_TEMPLATE_ID,
      personalisation: {otp: OneTimePassword::Generator.new.code}
    ).deliver!
  end

  def mobile_number_changed?
    mobile_number != answers.mobile_number
  end
end
