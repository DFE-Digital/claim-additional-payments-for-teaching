class MobileNumberForm < Form
  attribute :mobile_number
  attribute :resend, :boolean

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
    return true unless mobile_number_changed? || resend

    sent_one_time_password_at = if send_sms_message
      Time.now
    end

    journey_session.answers.assign_attributes(
      mobile_number: mobile_number,
      mobile_verified: nil,
      sent_one_time_password_at: sent_one_time_password_at
    )

    journey_session.save!
  rescue NotifySmsMessage::NotifySmsError => e
    handle_notify_error(e)
    false
  end

  private

  def send_sms_message
    if Rails.env.development?
      Rails.logger.info("\n\nSMS CODE: #{OneTimePassword::Generator.new.code}\n")
      return true
    end

    NotifySmsMessage.new(
      phone_number: mobile_number,
      template_id: NotifySmsMessage::OTP_PROMPT_TEMPLATE_ID,
      personalisation: {otp: OneTimePassword::Generator.new.code}
    ).deliver!
  end

  def mobile_number_changed?
    mobile_number != answers.mobile_number
  end

  def handle_notify_error(error)
    if error.message.include?("ValidationError: phone_number Number is not valid")
      errors.add(:mobile_number, i18n_errors_path("invalid"))
    else
      raise error
    end
  end
end
