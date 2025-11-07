require "rails_helper"

RSpec.describe ExpireJourneySessionsJob do
  describe "#perform" do
    let(:over_24_hours_ago) { 24.hours.ago - 1.second }
    let(:four_hours_ago) { 4.hours.ago }

    it "expires unsubmitted claims not touched for 24 hours" do
      submitted_journeys = []
      unsubmitted_fresh_journeys = []
      unsubmitted_expired_journeys = []

      Journeys::JOURNEYS.each do |journey|
        submitted_journeys << journey::Session.create!(
          journey: journey.routing_name,
          claim: create(:claim),
          updated_at: over_24_hours_ago
        )

        unsubmitted_fresh_journeys << journey::Session.create!(
          journey: journey.routing_name,
          updated_at: four_hours_ago
        )

        unsubmitted_expired_journeys << journey::Session.create!(
          journey: journey.routing_name,
          updated_at: over_24_hours_ago
        )
      end

      subject.perform

      expect(submitted_journeys.each(&:reload)).to all be_not_expired
      expect(unsubmitted_fresh_journeys.each(&:reload)).to all be_not_expired
      expect(unsubmitted_expired_journeys.each(&:reload)).to all be_expired
    end
  end
end
