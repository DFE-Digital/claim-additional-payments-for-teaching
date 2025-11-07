require "rails_helper"

RSpec.describe MobileVerificationForm do
  shared_examples "mobile_verification" do |journey|
    let(:secret) { ROTP::Base32.random }

    let(:journey_session) do
      create(
        :"#{journey.i18n_namespace}_session",
        answers: {
          mobile_verification_secret: secret,
          sent_one_time_password_at: sent_one_time_password_at
        }
      )
    end

    let(:params) do
      ActionController::Parameters.new(
        claim: {
          one_time_password: one_time_password
        }
      )
    end

    let(:form) do
      described_class.new(
        journey: journey,
        journey_session: journey_session,
        params: params
      )
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
          let(:one_time_password) { OneTimePassword::Generator.new(secret:).code }
          let(:sent_one_time_password_at) { 30.minutes.ago }
          it { is_expected.not_to be_valid }
        end

        context "when correct code" do
          let(:one_time_password) { OneTimePassword::Generator.new(secret:).code }
          let(:sent_one_time_password_at) { Time.now }
          it { is_expected.to be_valid }
        end
      end
    end

    describe "#save" do
      let(:one_time_password) { OneTimePassword::Generator.new(secret:).code }
      let(:sent_one_time_password_at) { Time.now }

      before { form.save }

      it "sets the mobile_verified attribute to true" do
        expect(journey_session.reload.answers.mobile_verified).to be true
      end
    end
  end

  describe "for TeacherStudentLoanReimbursement journey" do
    include_examples(
      "mobile_verification",
      Journeys::TeacherStudentLoanReimbursement
    )
  end

  describe "for TargetedRetentionIncentivePayments journey" do
    include_examples(
      "mobile_verification",
      Journeys::TargetedRetentionIncentivePayments
    )
  end
end
