require "rails_helper"

RSpec.describe MobileNumberForm do
  shared_examples "mobile_number_form" do |journey|
    let(:claims) do
      journey::POLICIES.map do |policy|
        create(
          :claim,
          :with_details_from_dfe_identity,
          policy: policy,
          mobile_verified: true
        )
      end
    end

    let(:current_claim) { CurrentClaim.new(claims: claims) }

    let(:params) do
      ActionController::Parameters.new(claim: {mobile_number: mobile_number})
    end

    let(:form) do
      described_class.new(journey: journey, claim: current_claim, params: params)
    end

    describe "validations" do
      subject { form }

      describe "#mobile_number" do
        context "when the mobile is missing" do
          let(:mobile_number) { nil }
          it { is_expected.not_to be_valid }
        end

        context "with UK number without spaces" do
          let(:mobile_number) { "07474000123" }
          it { is_expected.to be_valid(:mobile_number) }
        end

        context "with UK number with spaces" do
          let(:mobile_number) { "07474 000 123" }
          it { is_expected.to be_valid(:mobile_number) }
        end

        context "with international format number without spaces" do
          let(:mobile_number) { "+447474000123" }
          it { is_expected.to be_valid(:mobile_number) }
        end

        context "with international format number with spaces" do
          let(:mobile_number) { "+44 7474 000 123" }
          it { is_expected.to be_valid(:mobile_number) }
        end

        context "with international format non-UK number" do
          let(:mobile_number) { "+33 12 34 56 78" }
          it { is_expected.not_to be_valid(:mobile_number) }
        end
      end
    end

    describe "#save" do
      around do |example|
        travel_to DateTime.new(2024, 1, 1, 12, 0, 0) do
          example.run
        end
      end

      before do
        allow(OneTimePassword::Generator).to receive(:new).and_return(
          instance_double(OneTimePassword::Generator, code: "111111")
        )

        allow(NotifySmsMessage).to receive(:new).and_return(notify_double)

        form.save
      end

      let(:notify_double) do
        instance_double(NotifySmsMessage, deliver!: notify_response)
      end

      let(:mobile_number) { "07123456789" }

      context "when notify is successful" do
        let(:notify_response) do
          Notifications::Client::ResponseNotification.new(
            {
              id: "123",
              reference: "456",
              content: "content",
              template: "template",
              uri: "uri"
            }
          )
        end

        it "stores the mobile number" do
          claims.each do |claim|
            expect(claim.mobile_number).to eq(mobile_number)
          end
        end

        it "resets dependent attributes" do
          claims.each do |claim|
            expect(claim.mobile_verified).to be_nil
          end
        end

        it "sends a text message" do
          expect(NotifySmsMessage).to have_received(:new).with(
            phone_number: mobile_number,
            template_id: NotifySmsMessage::OTP_PROMPT_TEMPLATE_ID,
            personalisation: {
              otp: "111111"
            }
          )

          expect(notify_double).to have_received(:deliver!)
        end

        it "sets sent_one_time_password_at to the current time" do
          claims.each do |claim|
            expect(claim.sent_one_time_password_at).to(
              eq(DateTime.new(2024, 1, 1, 12, 0, 0))
            )
          end
        end
      end

      context "when notify is unsuccessful" do
        # Not sure how this could be nil rather than a bad response but that's
        # what the existing code checks for
        let(:notify_response) { nil }

        it "stores the mobile number" do
          claims.each do |claim|
            expect(claim.mobile_number).to eq(mobile_number)
          end
        end

        it "resets dependent attributes" do
          claims.each do |claim|
            expect(claim.mobile_verified).to be_nil
          end
        end

        it "sends a text message" do
          expect(NotifySmsMessage).to have_received(:new).with(
            phone_number: mobile_number,
            template_id: NotifySmsMessage::OTP_PROMPT_TEMPLATE_ID,
            personalisation: {
              otp: "111111"
            }
          )

          expect(notify_double).to have_received(:deliver!)
        end

        it "sets sent_one_time_password_at to nil" do
          claims.each do |claim|
            expect(claim.sent_one_time_password_at).to be_nil
          end
        end
      end
    end
  end

  describe "for TeacherStudentLoanReimbursement journey" do
    include_examples(
      "mobile_number_form",
      Journeys::TeacherStudentLoanReimbursement
    )
  end

  describe "for AdditionalPaymentsForTeaching journey" do
    include_examples(
      "mobile_number_form",
      Journeys::AdditionalPaymentsForTeaching
    )
  end
end
