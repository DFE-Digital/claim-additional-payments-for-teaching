require "rails_helper"

RSpec.describe CloseExpiredJourneysJob do
  describe "#perform" do
    it "keeps a journey open before the close time and closes it exactly at the close time" do
      journey_configuration = create(:journey_configuration, :student_loans, open_for_submissions: true, close_at: Time.zone.parse("2026-08-01 17:00:00"))

      travel_to Time.zone.parse("2026-08-01 16:59:00") do
        described_class.new.perform
        expect(journey_configuration.reload.open_for_submissions).to be(true)
      end

      travel_to Time.zone.parse("2026-08-01 17:00:00") do
        described_class.new.perform
        expect(journey_configuration.reload.open_for_submissions).to be(false)
      end
    end
  end
end
