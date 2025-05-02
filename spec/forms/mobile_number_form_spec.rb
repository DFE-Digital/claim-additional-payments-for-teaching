require "rails_helper"

RSpec.describe MobileNumberForm do
  shared_examples "mobile_number_form" do |journey|
    let(:journey_session) do
      create(
        :"#{journey::I18N_NAMESPACE}_session",
        answers: attributes_for(
          :"#{journey::I18N_NAMESPACE}_answers",
          :with_details_from_dfe_identity,
          mobile_verified: true
        )
      )
    end

    let(:params) do
      ActionController::Parameters.new(claim: {mobile_number: mobile_number})
    end

    let(:form) do
      described_class.new(
        journey: journey,
        journey_session: journey_session,
        params: params
      )
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
      subject { form.save }

      let(:mobile_number) { "07123456789" }
      let(:notify_double) { nil }

      before do
        travel_to DateTime.new(2024, 1, 1, 12, 0, 0)
        allow(OneTimePassword::Generator).to receive(:new).and_return(
          instance_double(OneTimePassword::Generator, code: "111111")
        )
        allow(NotifySmsMessage).to receive(:new) { notify_double }
      end

      context "when basic phone number validation fails" do
        # this is validation in the form, not an error raised by notify
        let(:mobile_number) { "0" }

        it "returns false" do
          expect(subject).to be false
        end

        it "does not send a text message" do
          subject
          expect(NotifySmsMessage).not_to have_received(:new)
        end
      end

      context "when the mobile number has not changed" do
        let(:journey_session) do
          create(
            :"#{journey::I18N_NAMESPACE}_session",
            answers: attributes_for(
              :"#{journey::I18N_NAMESPACE}_answers",
              :with_details_from_dfe_identity,
              mobile_number: mobile_number,
              mobile_verified: true
            )
          )
        end

        before { subject }

        it "returns true" do
          expect(subject).to be true
        end

        it "does not send a text message" do
          expect(NotifySmsMessage).not_to have_received(:new)
        end

        context "when the resend attribute is true" do
          let(:notify_double) { instance_double(NotifySmsMessage, deliver!: true) }
          let(:params) do
            ActionController::Parameters.new(claim: {mobile_number: mobile_number, resend: true})
          end

          it "sends a text message" do
            expect(notify_double).to have_received(:deliver!)
          end
        end
      end

      context "when notify response is successful" do
        let(:notify_double) do
          instance_double(
            NotifySmsMessage,
            deliver!: Notifications::Client::ResponseNotification.new(
              {
                id: "123",
                reference: "456",
                content: "content",
                template: "template",
                uri: "uri"
              }
            )
          )
        end

        before { subject }

        it "returns true" do
          expect(subject).to be true
        end

        it "stores the mobile number" do
          expect(journey_session.reload.answers.mobile_number).to eq(mobile_number)
        end

        it "resets dependent attributes" do
          expect(journey_session.reload.answers.mobile_verified).to be_nil
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
          expect(journey_session.reload.answers.sent_one_time_password_at).to(
            eq(DateTime.new(2024, 1, 1, 12, 0, 0))
          )
        end
      end

      context "when notify response is not successful" do
        context "when the notify response is nil" do
          let(:mobile_number) { "07123456789" }

          # Not sure how this could be nil rather than a bad response but that's
          # what the existing code checks for
          let(:notify_double) { instance_double(NotifySmsMessage, deliver!: nil) }

          before { subject }

          it "stores the mobile number" do
            expect(journey_session.reload.answers.mobile_number).to eq(mobile_number)
          end

          it "resets dependent attributes" do
            expect(journey_session.reload.answers.mobile_verified).to be_nil
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
            expect(journey_session.reload.answers.sent_one_time_password_at).to be_nil
          end
        end

        context "when the error is an invalid phone number" do
          let(:mobile_number) { "07123456789" }
          let(:notify_double) { instance_double(NotifySmsMessage) }

          before do
            allow(notify_double).to receive(:deliver!).and_raise(
              NotifySmsMessage::NotifySmsError,
              "ValidationError: phone_number Number is not valid – double check the phone number you entered"
            )
          end

          it "adds a validation error" do
            expect(subject).to eq false
            expect(form.errors[:mobile_number]).to include(
              "Enter a mobile number, like 07700 900 982 or +44 7700 900 982"
            )
            journey_session.reload
            expect(journey_session.answers.mobile_number).to be_nil
            expect(journey_session.answers.sent_one_time_password_at).to be_nil
          end
        end

        context "when some other error" do
          let(:mobile_number) { "07123456789" }
          let(:notify_double) { instance_double(NotifySmsMessage) }

          before do
            allow(notify_double).to receive(:deliver!).and_raise(
              NotifySmsMessage::NotifySmsError,
              "Something went wrong with the SMS service. Please try again later."
            )
          end

          it "raises the error" do
            expect { subject }.to raise_error(NotifySmsMessage::NotifySmsError)
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

  describe "for TargetedRetentionIncentivePayments journey" do
    include_examples(
      "mobile_number_form",
      Journeys::TargetedRetentionIncentivePayments
    )
  end
end
