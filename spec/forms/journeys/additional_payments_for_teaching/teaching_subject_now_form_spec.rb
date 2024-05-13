require "rails_helper"

RSpec.describe Journeys::AdditionalPaymentsForTeaching::TeachingSubjectNowForm do
  before { create(:journey_configuration, :additional_payments) }
  let(:journey) { Journeys::AdditionalPaymentsForTeaching }
  let(:journey_session) do
    build(:journeys_session, journey: journey::ROUTING_NAME)
  end
  let(:eligibility) { create(:early_career_payments_eligibility) }
  let(:claim) do
    create(
      :claim,
      policy: Policies::EarlyCareerPayments,
      eligibility: eligibility
    )
  end
  let(:current_claim) { CurrentClaim.new(claims: [claim]) }
  let(:form) do
    described_class.new(
      journey: journey,
      journey_session: journey_session,
      claim: current_claim,
      params: params
    )
  end

  describe "validations" do
    subject(:form_subject) { form }

    describe "teaching_subject_now" do
      context "when `true`" do
        let(:params) do
          ActionController::Parameters.new(claim: {teaching_subject_now: true})
        end

        it { is_expected.to be_valid }
      end

      context "when `false`" do
        let(:params) do
          ActionController::Parameters.new(claim: {teaching_subject_now: false})
        end

        it { is_expected.to be_valid }
      end

      context "when `nil`" do
        let(:params) do
          ActionController::Parameters.new(claim: {teaching_subject_now: nil})
        end

        it { is_expected.not_to be_valid }
      end
    end
  end

  describe "#save" do
    context "when invalid" do
      let(:params) do
        ActionController::Parameters.new(claim: {teaching_subject_now: nil})
      end

      it "returns false" do
        expect(form.save).to be false
      end
    end

    context "when valid" do
      let(:params) do
        ActionController::Parameters.new(claim: {teaching_subject_now: true})
      end

      it "returns true and updates the claim's eligibility" do
        expect { expect(form.save).to be true }.to(
          change { claim.reload.eligibility.teaching_subject_now }
            .from(nil).to(true)
        )
      end
    end
  end

  describe "#eligible_itt_subject" do
    let(:params) { ActionController::Parameters.new({}) }

    subject(:eligible_itt_subject) { form.eligible_itt_subject }

    it { is_expected.to eq claim.eligibility.eligible_itt_subject }
  end

  describe "#teaching_physics_or_chemistry?" do
    let(:params) { ActionController::Parameters.new({}) }

    subject(:teaching_physics_or_chemistry) do
      form.teaching_physics_or_chemistry?
    end

    context "when teaching physics" do
      let(:eligibility) do
        create(
          :early_career_payments_eligibility,
          eligible_itt_subject: "physics"
        )
      end

      it { is_expected.to be true }
    end

    context "when teaching chemistry" do
      let(:eligibility) do
        create(
          :early_career_payments_eligibility,
          eligible_itt_subject: "chemistry"
        )
      end

      it { is_expected.to be true }
    end

    context "when teaching neither physics nor chemistry" do
      let(:eligibility) do
        create(
          :early_career_payments_eligibility,
          eligible_itt_subject: "mathematics"
        )
      end

      it { is_expected.to be false }
    end
  end
end
