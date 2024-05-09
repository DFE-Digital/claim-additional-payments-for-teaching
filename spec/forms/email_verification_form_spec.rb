require "rails_helper"

RSpec.describe EmailVerificationForm do
  shared_examples "email_verification" do |journey|
    let(:claims) do
      journey::POLICIES.map do |policy|
        create(
          :claim,
          policy: policy,
          sent_one_time_password_at: sent_one_time_password_at
        )
      end
    end

    let(:current_claim) { CurrentClaim.new(claims: claims) }

    let(:params) do
      ActionController::Parameters.new(
        claim: {
          one_time_password: one_time_password
        }
      )
    end

    let(:form) do
      described_class.new(journey: journey, claim: current_claim, params: params)
    end

    around do |example|
      travel_to DateTime.new(2024, 1, 1, 12, 0, 0) do
        example.run
      end
    end

    describe "validations" do
      subject { form }
      describe "one_time_password" do
        context "when blank" do
          let(:one_time_password) { "" }
          let(:sent_one_time_password_at) { Time.now }
          it { is_expected.not_to be_valid }
        end

        context "when too short" do
          let(:one_time_password) { "12345" }
          let(:sent_one_time_password_at) { Time.now }
          it { is_expected.not_to be_valid }
        end

        context "when too long" do
          let(:one_time_password) { "1234567" }
          let(:sent_one_time_password_at) { Time.now }
          it { is_expected.not_to be_valid }
        end

        context "when incorrect code" do
          let(:one_time_password) { "123456" }
          let(:sent_one_time_password_at) { Time.now }
          it { is_expected.not_to be_valid }
        end

        context "when the code has expired" do
          let(:one_time_password) { OneTimePassword::Generator.new.code }
          let(:sent_one_time_password_at) { 30.minutes.ago }
          it { is_expected.not_to be_valid }
        end

        context "when correct code" do
          let(:one_time_password) { OneTimePassword::Generator.new.code }
          let(:sent_one_time_password_at) { Time.now }
          it { is_expected.to be_valid }
        end
      end
    end

    describe "#save" do
      let(:one_time_password) { OneTimePassword::Generator.new.code }
      let(:sent_one_time_password_at) { Time.now }

      before { form.save }

      it "sets the email_verified attribute to true" do
        claims.each do |claim|
          expect(claim.email_verified).to be true
        end
      end
    end
  end

  describe "for TeacherStudentLoanReimbursement journey" do
    include_examples(
      "email_verification",
      Journeys::TeacherStudentLoanReimbursement
    )
  end

  describe "for AdditionalPaymentsForTeaching journey" do
    include_examples(
      "email_verification",
      Journeys::AdditionalPaymentsForTeaching
    )
  end
end
