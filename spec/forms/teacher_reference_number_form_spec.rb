require "rails_helper"

RSpec.describe TeacherReferenceNumberForm do
  before { create(:journey_configuration, :additional_payments) }

  let(:journey) { Journeys::TargetedRetentionIncentivePayments }

  let(:journey_session) { build(:targeted_retention_incentive_payments_session) }

  let(:params) do
    ActionController::Parameters.new(
      claim: {
        teacher_reference_number: teacher_reference_number
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

  describe "#validations" do
    subject { form }

    describe "teacher_reference_number" do
      context "when the teacher_reference_number is blank" do
        let(:teacher_reference_number) { "" }

        it { is_expected.not_to be_valid }
      end

      context "when the teacher_reference_number is too short" do
        let(:teacher_reference_number) { "12345" }

        it { is_expected.not_to be_valid }
      end

      context "when the teacher_reference_number is too long" do
        let(:teacher_reference_number) { "12345678" }

        it { is_expected.not_to be_valid }
      end

      context "when the teacher_reference_number is 7 digits" do
        context "when the teacher_reference_number contains only digits" do
          let(:teacher_reference_number) { "1234567" }

          it { is_expected.to be_valid }
        end

        context "when the teacher_reference_number contains non digits" do
          let(:teacher_reference_number) { "12-34567" }

          it { is_expected.to be_valid }
        end
      end
    end
  end

  describe "#save" do
    before { form.save }

    context "when valid" do
      let(:teacher_reference_number) { "1234-567" }

      it "updates the teacher_reference_number on the claim" do
        expect(
          journey_session.reload.answers.teacher_reference_number
        ).to eq "1234567"
      end
    end
  end
end
