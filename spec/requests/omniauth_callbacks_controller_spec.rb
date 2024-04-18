require "rails_helper"

RSpec.describe "OmniauthCallbacksControllers", type: :request do
  # https://github.com/DFE-Digital/schools-experience/blob/master/spec/support/session_double.rb
  let(:session_hash) { {} }

  before do
    session_double = instance_double(
      ActionDispatch::Request::Session,
      enabled?: true,
      loaded?: false
    )

    allow(session_double).to receive(:[]) do |key|
      session_hash[key]
    end

    allow(session_double).to receive(:[]=) do |key, value|
      session_hash[key] = value
    end

    allow(session_double).to receive(:delete) do |key|
      session_hash.delete(key)
    end

    allow(session_double).to receive(:clear) do |_key|
      session_hash.clear
    end

    allow(session_double).to receive(:fetch) do |key|
      session_hash.fetch(key)
    end

    allow(session_double).to receive(:key?) do |key|
      session_hash.key?(key)
    end

    allow_any_instance_of(ActionDispatch::Request).to(
      receive(:session).and_return(session_double)
    )
  end

  describe "#callback" do
    def set_mock_auth(trn)
      OmniAuth.config.mock_auth[:tid] = OmniAuth::AuthHash.new(
        "extra" => {
          "raw_info" => {
            "trn" => trn
          }
        }
      )
      Rails.application.env_config["omniauth.auth"] = OmniAuth.config.mock_auth[:tid]
    end

    before do
      create(:journey_configuration, :additional_payments)
      create(:journey_configuration, :student_loans)
    end

    context "when trn is not nil" do
      let(:ecp_claim) do
        create(
          :claim,
          policy: Policies::EarlyCareerPayments,
          details_check: true
        )
      end

      let(:lup_claim) do
        create(
          :claim,
          policy: Policies::LevellingUpPremiumPayments,
          details_check: true
        )
      end

      before do
        set_mock_auth("1234567")

        session_hash[:claim_id] = [ecp_claim.id, lup_claim.id]

        get claim_auth_tid_callback_path
      end

      it "resets details check on the claims" do
        expect(ecp_claim.reload.details_check).to be nil
        expect(lup_claim.reload.details_check).to be nil
      end

      it "sets the teacher details to the value from auth payload" do
        expect(ecp_claim.reload.teacher_id_user_info).to eq("trn" => "1234567")
        expect(lup_claim.reload.teacher_id_user_info).to eq("trn" => "1234567")
      end

      it "redirects to the claim path with correct parameters" do
        expect(response).to redirect_to(
          claim_path(journey: "additional-payments", slug: "teacher-detail")
        )
      end
    end

    context "when trn is nil" do
      let(:ecp_claim) do
        create(
          :claim,
          policy: Policies::EarlyCareerPayments,
          details_check: true
        )
      end

      let(:lup_claim) do
        create(
          :claim,
          policy: Policies::LevellingUpPremiumPayments,
          details_check: true
        )
      end

      before do
        set_mock_auth(nil)

        session_hash[:claim_id] = [ecp_claim.id, lup_claim.id]

        get claim_auth_tid_callback_path
      end

      it "resets details check on the claims" do
        expect(ecp_claim.reload.details_check).to be nil
        expect(lup_claim.reload.details_check).to be nil
      end

      it "doesn't set teacher_id_user_info" do
        expect(ecp_claim.reload.teacher_id_user_info).to be_empty
        expect(lup_claim.reload.teacher_id_user_info).to be_empty
      end

      it "redirects to the claim path with correct parameters" do
        expect(response).to redirect_to(
          claim_path(journey: "additional-payments", slug: "teacher-detail")
        )
      end
    end

    context "when there is no current claim" do
      before do
        set_mock_auth(nil)

        get claim_auth_tid_callback_path
      end

      it "redirects to the first policy journey" do
        expect(response).to redirect_to(
          claim_path(journey: "student-loans", slug: "teacher-detail")
        )
      end
    end

    context "auth failure csrf detected" do
      it "redirects to /auth/failure" do
        OmniAuth.config.mock_auth[:tid] = :csrf_detected

        get claim_auth_tid_callback_path

        expect(response).to redirect_to(
          auth_failure_path(message: "csrf_detected", strategy: "tid")
        )
      end
    end
  end
end
