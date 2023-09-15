require "rails_helper"

RSpec.describe "OmniauthCallbacksControllers", type: :request do
  describe "#callback" do
    def set_mock_auth(trn)
      OmniAuth.config.mock_auth[:default] = OmniAuth::AuthHash.new(
        "extra" => {
          "raw_info" => {
            "trn" => trn
          }
        }
      )
      Rails.application.env_config["omniauth.auth"] = OmniAuth.config.mock_auth[:default]
    end

    context "when trn is not nil" do
      before do
        set_mock_auth("12345678")
      end

      it "redirects to the claim path with correct parameters" do
        get claim_auth_tid_callback_path

        expect(response).to redirect_to(
          teacher_detail_path(policy: "additional-payments")
        )
      end
    end

    context "when trn is nil" do
      before do
        set_mock_auth(nil)
      end

      it "redirects to the claim path with correct parameters" do
        get claim_auth_tid_callback_path

        expect(response).to redirect_to(
          teacher_detail_path(policy: "additional-payments")
        )
      end
    end
  end
end
