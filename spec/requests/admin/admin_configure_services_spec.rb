require "rails_helper"

RSpec.describe "Service configuration" do
  let(:journey_configuration) { create(:journey_configuration, :student_loans) }

  context "when signed in as a service operator" do
    before { sign_in_as_service_operator }

    describe "admin_journey_configurations#update" do
      it "sets the configuration's availability message and status" do
        patch admin_journey_configuration_path(journey_configuration, journey_configuration: {open_for_submissions: false, availability_message: "Test message"})

        expect(response).to redirect_to(admin_journey_configurations_path)

        journey_configuration.reload
        expect(journey_configuration.open_for_submissions).to be false
        expect(journey_configuration.availability_message).to eq("Test message")
      end
    end
  end

  context "when signed in as a support agent" do
    describe "admin_journey_configurations#update" do
      it "returns a unauthorized response" do
        sign_in_to_admin_with_role(DfeSignIn::User::SUPPORT_AGENT_DFE_SIGN_IN_ROLE_CODE)

        patch admin_journey_configuration_path(journey_configuration, journey_configuration: {open_for_submissions: false, availability_message: "Test message"})

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
