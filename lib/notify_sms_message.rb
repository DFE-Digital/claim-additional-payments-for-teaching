require "notifications/client"

class NotifySmsMessage
  class NotifySmsError < StandardError; end

  attr_reader :phone_number, :template_id, :personalisation

  def initialize(phone_number:, template_id:, personalisation:)
    @phone_number = phone_number
    @template_id = template_id
    @personalisation = personalisation
  end

  def deliver!
    sms_client.send_sms(
      phone_number: phone_number,
      template_id: template_id,
      personalisation: personalisation
    )
  rescue Notifications::Client::RequestError => e
    Rails.logger.error(e.message)
    raise NotifySmsError, e
  end

  private

  def sms_client
    @sms_client ||= Notifications::Client.new(api_key)
  end

  def api_key
    ENV["NOTIFY_API_KEY"]
  end
end
