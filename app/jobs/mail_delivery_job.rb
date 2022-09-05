class MailDeliveryJob < ActionMailer::MailDeliveryJob
  def priority
    10
  end
end
