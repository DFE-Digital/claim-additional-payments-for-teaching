require "rails_helper"

RSpec.describe EmailAddressForm do
  shared_examples "email_address_form" do |journey|
    let(:journey_session) do
      create(
        :"#{journey::I18N_NAMESPACE}_session",
        answers: attributes_for(
          :"#{journey::I18N_NAMESPACE}_answers",
          :with_personal_details,
          email_verified: true,
          first_name: "Jo"
        )
      )
    end

    let(:current_claim) { CurrentClaim.new(claims: claims) }

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

      describe "email_address" do
        context "when missing" do
          let(:email_address) { nil }
          it { is_expected.not_to be_valid }
        end

        context "when too long" do
          let(:email_address) { "a" * 257 }
          it { is_expected.not_to be_valid }
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
      around do |example|
        travel_to DateTime.new(2024, 1, 1, 12, 0, 0) do
          example.run
        end
      end

      before do
        allow(OneTimePassword::Generator).to receive(:new).and_return(
          instance_double(OneTimePassword::Generator, code: "111111")
        )

        form.save
      end

      let(:email_address) { "test@example.com" }

      it "sets the email address" do
        expect(journey_session.reload.answers.email_address).to(
          eq(email_address)
        )
      end

      it "sends an email" do
        policy = journey_session.answers.policy

        support_email_address = I18n.t(
          "#{policy.locale_key}.support_email_address"
        )

        claim_subject = I18n.t("#{policy.locale_key}.claim_subject")

        email_subject = "#{claim_subject} email verification"

        expect(email_address).to have_received_email(
          "89e8c33a-1863-4fdd-a73c-1ca01efc0c76",
          email_subject: email_subject,
          first_name: "Jo",
          one_time_password: "111111",
          support_email_address: support_email_address
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
    end
  end

  describe "for TeacherStudentLoanReimbursement journey" do
    include_examples(
      "email_address_form",
      Journeys::TeacherStudentLoanReimbursement
    )
  end

  describe "for AdditionalPaymentsForTeaching journey" do
    include_examples(
      "email_address_form",
      Journeys::AdditionalPaymentsForTeaching
    )
  end
end
