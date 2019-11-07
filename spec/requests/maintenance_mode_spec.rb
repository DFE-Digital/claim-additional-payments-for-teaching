require "rails_helper"

RSpec.describe "Maintenance Mode", type: :request do
  context "when a policy configuration is closed for submissions" do
    let(:policy_configuration) { policy_configurations(:student_loans) }
    before { policy_configuration.update(open_for_submissions: false) }

    it "shows the policy closed page for GET requests" do
      get new_claim_path(StudentLoans.routing_name)
      expect(response).to have_http_status(:service_unavailable)
      expect(response.body).to include("service is unavailable")
      expect(response.body).to include("You will be able to use the service later today.")
    end

    it "shows the policy closed page for POST requests" do
      post claims_path(StudentLoans.routing_name)
      expect(response).to have_http_status(:service_unavailable)
      expect(response.body).to include("service is unavailable")
    end

    it "still allows access to /admin for service operator access" do
      get admin_root_path
      expect(response).to redirect_to(admin_sign_in_path)

      get admin_sign_in_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Sign in with DfE Sign In")
    end

    it "still allows access to a different policy" do
      get new_claim_path(MathsAndPhysics.routing_name)
      expect(response).to have_http_status(:ok)
    end

    it "still allows access to the static pages" do
      get privacy_notice_path(StudentLoans.routing_name)
      expect(response).to have_http_status(:ok)
    end

    context "when the availability message is set" do
      let(:availability_message) { "You will be able to use the service from 2pm today" }
      before { policy_configuration.update(availability_message: availability_message) }

      it "shows the time it will be available from" do
        get new_claim_path(StudentLoans.routing_name)
        expect(response.body).to include(availability_message)
      end
    end
  end
end
