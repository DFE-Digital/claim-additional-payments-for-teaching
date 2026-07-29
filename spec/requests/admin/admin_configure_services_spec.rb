require "rails_helper"

RSpec.describe "Service configuration" do
  let(:journey_configuration) { create(:journey_configuration, :student_loans) }

  context "when signed in as a service operator" do
    before { sign_in_as_service_operator }

    describe "admin_journey_configurations#update" do
      it "sets the configuration's availability message, status, and close date/time" do
        close_date = Date.current

        patch admin_journey_configuration_path(journey_configuration, journey_configuration: {
          open_for_submissions: false,
          availability_message: "Test message",
          close_date: close_date,
          close_time: "12:00"
        })

        expect(response).to redirect_to(admin_journey_configurations_path)

        journey_configuration.reload
        expect(journey_configuration.open_for_submissions).to be false
        expect(journey_configuration.availability_message).to eq("Test message")
        expect(journey_configuration.close_date).to eq(close_date)
        expect(journey_configuration.close_time).to eq(Time.utc(2000, 1, 1, 12, 0, 0))
      end

      it "persists close date and time for the early years payment practitioner journey" do
        practitioner_journey_configuration = create(:journey_configuration, :early_years_payment_practitioner)
        close_date = Date.current

        patch admin_journey_configuration_path(practitioner_journey_configuration, journey_configuration: {
          open_for_submissions: false,
          availability_message: "Practitioner journey message",
          close_date: close_date,
          close_time: "12:00"
        })

        expect(response).to redirect_to(admin_journey_configurations_path)

        practitioner_journey_configuration.reload
        expect(practitioner_journey_configuration.close_date).to eq(close_date)
        expect(practitioner_journey_configuration.close_time).to eq(Time.utc(2000, 1, 1, 12, 0, 0))
      end

      it "requires a close date and time when the service is opened" do
        patch admin_journey_configuration_path(journey_configuration, journey_configuration: {
          open_for_submissions: true,
          close_date: "",
          close_time: ""
        })

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end
end
