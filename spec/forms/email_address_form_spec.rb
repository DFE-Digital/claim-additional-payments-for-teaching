require "rails_helper"

RSpec.describe EmailAddressForm do
  shared_examples "email_address_form" do |journey|
    let(:journey_session) do
      create(
        :"#{journey.i18n_namespace}_session",
        answers: attributes_for(
          :"#{journey.i18n_namespace}_answers",
          :with_personal_details,
          email_verified: true,
          first_name: "Jo"
        )
      )
    end

    let(:params) do
      ActionController::Parameters.new(claim: {email_address: email_address})
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

      let(:domain) { "@example.com" }

      describe "email_address" do
        context "when missing" do
          let(:email_address) { nil }
          it { is_expected.not_to be_valid }
        end

        context "when too long" do
          let(:email_address) { "#{"a" * (130 - domain.length)}#{domain}" }
          it do
            subject.valid?

            expect(form).not_to be_valid
            expect(form.errors.added?(:email_address, :too_long, count: 129)).to be true
            expect(form.errors.messages[:email_address]).to include("Email address must be 129 characters or less")
          end
        end

        context "when as long as it can get" do
          let(:email_address) { "#{"a" * (129 - domain.length)}#{domain}" }
          it { is_expected.to be_valid }
        end

        context "when the wrong format" do
          let(:email_address) { "not_an_email" }
          it { is_expected.not_to be_valid }
        end

        context "when the correct format" do
          let(:email_address) { "test@example.com" }
          it { is_expected.to be_valid }
        end
      end
    end

    describe "#save" do
      subject { form.save }

      before do
        travel_to DateTime.new(2024, 1, 1, 12, 0, 0)
        allow(OneTimePassword::Generator).to receive(:new).and_return(
          instance_double(OneTimePassword::Generator, code: "111111")
        )

        subject
      end

      let(:email_address) { "test@example.com" }
      let(:policy) { journey_session.answers.policy }
      let(:support_email_address) { I18n.t("#{policy.locale_key}.support_email_address") }
      let(:claim_subject) { I18n.t("#{policy.locale_key}.claim_subject") }
      let(:email_subject) { "#{claim_subject} email verification" }

      it "sets the email address" do
        expect(journey_session.reload.answers.email_address).to(
          eq(email_address)
        )
      end

      it "sends an email" do
        expect(email_address).to have_received_email(
          "89e8c33a-1863-4fdd-a73c-1ca01efc0c76",
          email_subject: email_subject,
          first_name: "Jo",
          one_time_password: "111111",
          support_email_address: support_email_address,
          journey_name: journey_session.journey_class.journey_name
        )
      end

      it "updates sent_one_time_password_at" do
        expect(journey_session.answers.sent_one_time_password_at).to(
          eq(DateTime.new(2024, 1, 1, 12, 0, 0))
        )
      end

      it "resets email_verified" do
        expect(journey_session.answers.email_verified).to be_nil
      end

      context "when the email address is invalid" do
        let(:email_address) { "test" }

        it "returns false" do
          expect(subject).to be false
        end

        it "does not send an email" do
          expect(email_address).not_to have_received_email
        end
      end

      context "when the email address has not changed" do
        let(:journey_session) do
          create(
            :"#{journey.i18n_namespace}_session",
            answers: attributes_for(
              :"#{journey.i18n_namespace}_answers",
              :with_personal_details,
              email_address: email_address,
              email_verified: true,
              first_name: "Jo"
            )
          )
        end

        it "returns true" do
          expect(subject).to be true
        end

        it "does not send an email" do
          expect(email_address).not_to have_received_email
        end

        context "when the resend attribute is true" do
          let(:params) do
            ActionController::Parameters.new(claim: {email_address: email_address, resend: true})
          end

          it "sends an email" do
            expect(email_address).to have_received_email(
              "89e8c33a-1863-4fdd-a73c-1ca01efc0c76",
              email_subject: email_subject,
              first_name: "Jo",
              one_time_password: "111111",
              support_email_address: support_email_address
            )
          end
        end
      end
    end
  end

  describe "for TeacherStudentLoanReimbursement journey" do
    include_examples(
      "email_address_form",
      Journeys::TeacherStudentLoanReimbursement
    )
  end

  describe "for TargetedRetentionIncentivePayments journey" do
    include_examples(
      "email_address_form",
      Journeys::TargetedRetentionIncentivePayments
    )
  end
end
