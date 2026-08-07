require "rails_helper"

RSpec.describe "Service configuration" do
  let(:journey_configuration) { create(:journey_configuration, :student_loans) }

  context "when signed in as a service operator" do
    before { sign_in_as_service_operator }

    describe "admin_journey_configurations#update" do
      it "sets the configuration's availability message, status, and close datetime" do
        close_at = 2.days.from_now.change(sec: 0)

        patch admin_journey_configuration_path(journey_configuration, journey_configuration: {
          open_for_submissions: false,
          availability_message: "Test message",
          close_at: close_at
        })

        expect(response).to redirect_to(edit_admin_journey_configuration_path(journey_configuration))

        journey_configuration.reload
        expect(journey_configuration.open_for_submissions).to be false
        expect(journey_configuration.availability_message).to eq("Test message")
        expect(journey_configuration.close_at).to eq(close_at)
      end

      it "persists close datetime for the early years payment practitioner journey" do
        practitioner_journey_configuration = create(:journey_configuration, :early_years_payment_practitioner)
        close_at = 2.days.from_now.change(sec: 0)

        patch admin_journey_configuration_path(practitioner_journey_configuration, journey_configuration: {
          open_for_submissions: false,
          availability_message: "Practitioner journey message",
          close_at: close_at
        })

        expect(response).to redirect_to(edit_admin_journey_configuration_path(practitioner_journey_configuration))

        practitioner_journey_configuration.reload
        expect(practitioner_journey_configuration.close_at).to eq(close_at)
      end

      it "requires a close datetime when the service is opened" do
        patch admin_journey_configuration_path(journey_configuration, journey_configuration: {
          open_for_submissions: true,
          close_at: ""
        })

        expect(response).to have_http_status(:unprocessable_content)
      end

      it "parses a close datetime in the Europe/London timezone for BST" do
        travel_to Time.zone.parse("2026-07-15 12:00:00 +01:00") do
          sign_in_as_service_operator

          patch admin_journey_configuration_path(journey_configuration, journey_configuration: {
            open_for_submissions: false,
            close_at: "2026-07-15T17:00"
          })

          expect(response).to redirect_to(edit_admin_journey_configuration_path(journey_configuration))
          expect(journey_configuration.reload.close_at).to eq(Time.zone.parse("2026-07-15 17:00:00 +01:00"))
        end
      end

      it "parses a close datetime in the Europe/London timezone for GMT" do
        travel_to Time.zone.parse("2026-12-15 12:00:00 +00:00") do
          sign_in_as_service_operator

          patch admin_journey_configuration_path(journey_configuration, journey_configuration: {
            open_for_submissions: false,
            close_at: "2026-12-15T17:00"
          })

          expect(response).to redirect_to(edit_admin_journey_configuration_path(journey_configuration))
          expect(journey_configuration.reload.close_at).to eq(Time.zone.parse("2026-12-15 17:00:00 +00:00"))
        end
      end

      it "keeps the same UTC instant when the close datetime is read later in the year" do
        travel_to Time.zone.parse("2026-07-15 12:00:00 +01:00") do
          sign_in_as_service_operator

          patch admin_journey_configuration_path(journey_configuration, journey_configuration: {
            open_for_submissions: false,
            close_at: "2026-07-15T17:00"
          })

          expect(journey_configuration.reload.close_at.utc).to eq(Time.utc(2026, 7, 15, 16, 0, 0))
        end

        travel_to Time.zone.parse("2026-12-15 12:00:00 +00:00") do
          expect(journey_configuration.reload.close_at.utc).to eq(Time.utc(2026, 7, 15, 16, 0, 0))
        end
      end
    end
  end
end
