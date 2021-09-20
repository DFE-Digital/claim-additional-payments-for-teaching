require "rails_helper"

RSpec.describe NotifySmsMessage do
  let(:claim) { build_stubbed(:claim, mobile_number: "07773335643", policy: EarlyCareerPayments) }
  let(:message) do
    described_class.new(
      phone_number: claim.mobile_number,
      template_id: "1234",
      personalisation: {
        otp: "239122"
      }
    )
  end
  let(:sms_client) { instance_double("Notifications::Client") }

  describe "#deliver!" do
    before do
      allow(sms_client).to receive(:send_sms)
      message.send(:instance_variable_set, :@sms_client, sms_client)
    end

    it "sends a SMS message" do
      message.deliver!
      expect(sms_client).to have_received(:send_sms).once
    end

    context "when the Nofify client raises an error" do
      before do
        err = instance_double("Net::HTTPClientError", code: 400, body: "boom")

        message.send(:instance_variable_set, :@sms_client, sms_client)
        allow(sms_client).to receive(:send_sms).and_raise(NotifySmsMessage::NotifySmsError, err)
      end

      it "catches the error and raises a NotifySMSError" do
        expect { message.deliver! }.to raise_error(NotifySmsMessage::NotifySmsError)
      end
    end
  end
end
