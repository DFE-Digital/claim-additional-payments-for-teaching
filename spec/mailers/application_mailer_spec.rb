require "rails_helper"

RSpec.describe ApplicationMailer, type: :mailer do
  describe ".deliver_later_with_throttling" do
    let(:mail_delivery) { instance_double(ActionMailer::MessageDelivery) }

    it "delivers later with a throttled wait based on the index" do
      allow(mail_delivery).to receive(:deliver_later)

      described_class.deliver_later_with_throttling(mail_delivery, index: 2)

      expect(mail_delivery).to have_received(:deliver_later).with(wait: 0.2.seconds)
    end

    it "preserves an explicitly provided wait" do
      allow(mail_delivery).to receive(:deliver_later)

      described_class.deliver_later_with_throttling(mail_delivery, index: 2, wait: 5.seconds)

      expect(mail_delivery).to have_received(:deliver_later).with(wait: 5.seconds)
    end
  end
end
