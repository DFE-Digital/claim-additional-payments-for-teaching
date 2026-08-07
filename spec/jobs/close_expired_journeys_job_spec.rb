require "rails_helper"

RSpec.describe CloseExpiredJourneysJob do
  describe "#perform" do
    let!(:admin_user) { create(:dfe_signin_user) }

    def future_close_at(days_from_now)
      Time.zone.now.in_time_zone("London") + days_from_now.days
    end

    before do
      allow(AdminMailer).to receive(:service_closing_soon).and_call_original
    end

    it "keeps a journey open before the close time and closes it exactly at the close time" do
      close_at = future_close_at(1)
      journey_configuration = create(:journey_configuration, :student_loans, open_for_submissions: true, close_at: close_at)

      travel_to(close_at - 1.minute) do
        described_class.new.perform
        expect(journey_configuration.reload.open_for_submissions).to be(true)
      end

      travel_to(close_at) do
        described_class.new.perform
        expect(journey_configuration.reload.open_for_submissions).to be(false)
        expect(journey_configuration.reload.close_at).to be_nil
      end
    end

    it "sends an admin notification one week before the close time" do
      close_at = future_close_at(8)
      journey_configuration = create(:journey_configuration, :student_loans, open_for_submissions: true, close_at: close_at)

      travel_to(close_at - 7.days) do
        described_class.new.perform

        expect(AdminMailer).to have_received(:service_closing_soon).with(
          admin_user.email,
          journey_name: journey_configuration.journey.journey_name,
          close_at: journey_configuration.close_at
        )
      end
    end

    it "sends an admin notification two days before the close time" do
      close_at = future_close_at(3)
      journey_configuration = create(:journey_configuration, :student_loans, open_for_submissions: true, close_at: close_at)

      travel_to(close_at - 2.days) do
        described_class.new.perform

        expect(AdminMailer).to have_received(:service_closing_soon).with(
          admin_user.email,
          journey_name: journey_configuration.journey.journey_name,
          close_at: journey_configuration.close_at
        )
      end
    end

    it "uses the latest close_at value when it changes before the reminder window" do
      original_close_at = future_close_at(10)
      updated_close_at = future_close_at(3)
      journey_configuration = create(:journey_configuration, :student_loans, open_for_submissions: true, close_at: original_close_at)

      travel_to(updated_close_at - 2.days) do
        journey_configuration.update!(close_at: updated_close_at)
        described_class.new.perform

        expect(AdminMailer).to have_received(:service_closing_soon).with(
          admin_user.email,
          journey_name: journey_configuration.journey.journey_name,
          close_at: journey_configuration.reload.close_at
        )
      end
    end

    it "does not send an admin notification before the reminder window" do
      close_at = future_close_at(10)
      create(:journey_configuration, :student_loans, open_for_submissions: true, close_at: close_at)

      travel_to(close_at - 8.days) do
        described_class.new.perform

        expect(AdminMailer).not_to have_received(:service_closing_soon)
      end
    end
  end
end
