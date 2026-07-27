require "rails_helper"

RSpec.describe CloseExpiredJourneysJob do
  describe "#perform" do
    let!(:admin_user) { create(:dfe_signin_user) }

    before do
      allow(AdminMailer).to receive(:service_closing_soon).and_call_original
    end

    it "keeps a journey open before the close time and closes it exactly at the close time" do
      journey_configuration = create(:journey_configuration, :student_loans, open_for_submissions: true, close_at: Time.zone.parse("2026-08-01 17:00:00"))

      travel_to Time.zone.parse("2026-08-01 16:59:00") do
        described_class.new.perform
        expect(journey_configuration.reload.open_for_submissions).to be(true)
      end

      travel_to Time.zone.parse("2026-08-01 17:00:00") do
        described_class.new.perform
        expect(journey_configuration.reload.open_for_submissions).to be(false)
        expect(journey_configuration.reload.close_at).to be_nil
      end
    end

    it "sends an admin notification one week before the close time" do
      journey_configuration = create(:journey_configuration, :student_loans, open_for_submissions: true, close_at: Time.zone.parse("2026-08-08 17:00:00"))

      travel_to Time.zone.parse("2026-08-01 17:00:00") do
        described_class.new.perform

        expect(AdminMailer).to have_received(:service_closing_soon).with(
          admin_user.email,
          journey_name: journey_configuration.journey.journey_name,
          close_at: journey_configuration.close_at
        )
      end
    end

    it "sends an admin notification two days before the close time" do
      journey_configuration = create(:journey_configuration, :student_loans, open_for_submissions: true, close_at: Time.zone.parse("2026-08-03 17:00:00"))

      travel_to Time.zone.parse("2026-08-01 17:00:00") do
        described_class.new.perform

        expect(AdminMailer).to have_received(:service_closing_soon).with(
          admin_user.email,
          journey_name: journey_configuration.journey.journey_name,
          close_at: journey_configuration.close_at
        )
      end
    end

    it "does not send an admin notification before the reminder window" do
      create(:journey_configuration, :student_loans, open_for_submissions: true, close_at: Time.zone.parse("2026-08-10 17:00:00"))

      travel_to Time.zone.parse("2026-08-01 17:00:00") do
        described_class.new.perform

        expect(AdminMailer).not_to have_received(:service_closing_soon)
      end
    end
  end
end
