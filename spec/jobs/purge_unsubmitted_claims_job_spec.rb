require "rails_helper"

RSpec.describe PurgeUnsubmittedClaimsJob do
  describe "#perform" do
    let(:over_24_hours_ago) { 24.hours.ago - 1.second }
    let(:four_hours_ago) { 4.hours.ago }

    it "destroys any unsubmitted claims that have not been updated in the last 24 hours" do
      submitted_journeys = []
      unsubmitted_fresh_journeys = []
      unsubmitted_expired_journeys = []

      Journeys::JOURNEYS.each do |journey|
        submitted_journeys << journey::Session.create!(
          journey: journey::ROUTING_NAME,
          claim: create(:claim),
          updated_at: over_24_hours_ago
        )

        unsubmitted_fresh_journeys << journey::Session.create!(
          journey: journey::ROUTING_NAME,
          updated_at: four_hours_ago
        )

        unsubmitted_expired_journeys << journey::Session.create!(
          journey: journey::ROUTING_NAME,
          updated_at: over_24_hours_ago
        )
      end

      PurgeUnsubmittedClaimsJob.new.perform

      expect(submitted_journeys.each(&:reload)).to all be_persisted

      expect(unsubmitted_fresh_journeys.each(&:reload)).to all be_persisted

      expect(
        Journeys::Session.where(id: unsubmitted_expired_journeys.map(&:id))
      ).to be_empty
    end
  end
end
