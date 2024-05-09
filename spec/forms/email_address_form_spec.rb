require "rails_helper"

RSpec.describe EmailAddressForm do
  shared_examples "email_address_form" do |journey|
    let(:claims) do
      journey::POLICIES.map do |policy|
        create(
          :claim,
          :with_details_from_dfe_identity,
          policy: policy,
          email_verified: true
        )
      end
    end

    let(:current_claim) { CurrentClaim.new(claims: claims) }

    let(:params) do
      ActionController::Parameters.new(claim: {email_address: email_address})
    end

    let(:form) do
      described_class.new(journey: journey, claim: current_claim, params: params)
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

        allow(ClaimMailer).to receive(:email_verification).and_return(
          claim_mailer_double
        )

        form.save
      end

      let(:claim_mailer_double) { double(deliver_now: true) }

      let(:email_address) { "test@example.com" }

      it "sends an email" do
        expect(ClaimMailer).to have_received(:email_verification).with(
          current_claim,
          "111111"
        )

        expect(claim_mailer_double).to have_received(:deliver_now)
      end

      it "updates sent_one_time_password_at" do
        claims.each do |claim|
          expect(claim.sent_one_time_password_at).to(
            eq(DateTime.new(2024, 1, 1, 12, 0, 0))
          )
        end
      end

      it "resets email_verified" do
        claims.each do |claim|
          expect(claim.email_verified).to be_nil
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

  describe "for AdditionalPaymentsForTeaching journey" do
    include_examples(
      "email_address_form",
      Journeys::AdditionalPaymentsForTeaching
    )
  end
end
