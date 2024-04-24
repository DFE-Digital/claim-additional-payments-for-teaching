class MobileNumberForm < Form
  attribute :mobile_number

  validates :mobile_number,
    presence: {
      message: "Enter a mobile number, like 07700 900 982 or +44 7700 900 982"
    }

  validates :mobile_number,
    format: {
      with: /\A(\+44\s?)?(?:\d\s?){10,11}\z/,
      message: "Enter a valid mobile number, like 07700 900 982 or +44 7700 900 982"
    },
    if: -> { mobile_number.present? }

  def save
    return false unless valid?

    sent_one_time_password_at = if send_sms_message
      Time.now
    end

    update!(
      mobile_number: mobile_number,
      mobile_verified: nil,
      sent_one_time_password_at: sent_one_time_password_at
    )
  end

  private

  def send_sms_message
    NotifySmsMessage.new(
      phone_number: mobile_number,
      template_id: "86ae1fe4-4f98-460b-9d57-181804b4e218",
      personalisation: {otp: OneTimePassword::Generator.new.code}
    ).deliver!
  end
end
