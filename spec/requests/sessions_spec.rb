require "rails_helper"

RSpec.describe "Sessions", type: :request do
  describe "#refresh" do
    it "updates the last_seen_at session timestamp and responds with OK" do
      travel_to(1.day.from_now) do
        get refresh_session_path

        expect(session[:last_seen_at]).to eql(Time.zone.now)
        expect(response).to have_http_status(:ok)
      end
    end

    it "does not extend an expired public user session" do
      start_student_loans_claim

      travel(2.hours) do
        get refresh_session_path
        expect(session[:claim_id]).to be_nil

        get claim_path(StudentLoans.routing_name, "qts-year")
        expect(response).to redirect_to(new_claim_path(StudentLoans.routing_name))
      end
    end

    it "does not extend an expired admin session" do
      sign_in_to_admin_with_role(DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE, "_user_id", "_org_id")

      travel(2.hours) do
        get refresh_session_path

        expect(session[:user_id]).to be_nil

        get admin_root_path
        expect(response).to redirect_to(admin_sign_in_path)
      end
    end
  end
end
