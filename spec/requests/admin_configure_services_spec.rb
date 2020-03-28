require "rails_helper"

RSpec.describe "Service configuration" do
  let(:policy_configuration) { policy_configurations(:student_loans) }

  context "when signed in as a service operator" do
    before { sign_in_as_service_operator }

    describe "admin_policy_configurations#update" do
      it "sets the configuration's availability message and status" do
        patch admin_policy_configuration_path(policy_configuration, policy_configuration: {open_for_submissions: false, availability_message: "Test message"})

        expect(response).to redirect_to(admin_policy_configurations_path)

        policy_configuration.reload
        expect(policy_configuration.open_for_submissions).to be false
        expect(policy_configuration.availability_message).to eq("Test message")
      end
    end
  end

  context "when signed in as a payroll operator or a support agent" do
    describe "admin_policy_configurations#update" do
      [DfeSignIn::User::SUPPORT_AGENT_DFE_SIGN_IN_ROLE_CODE, DfeSignIn::User::PAYROLL_OPERATOR_DFE_SIGN_IN_ROLE_CODE].each do |role|
        it "returns a unauthorized response" do
          sign_in_to_admin_with_role(role)

          patch admin_policy_configuration_path(policy_configuration, policy_configuration: {open_for_submissions: false, availability_message: "Test message"})

          expect(response).to have_http_status(:unauthorized)
        end
      end
    end
  end
end
