require "rails_helper"

RSpec.describe PurgeUnsubmittedClaimsJob do
  describe "#perform" do
    let(:over_24_hours_ago) { 24.hours.ago - 1.second }
    let(:four_hours_ago) { 4.hours.ago }

    it "destroys any unsubmitted claims that have not been updated in the last 24 hours" do
      submitted_journeys = []
      unsubmitted_fresh_journeys = []
      unsubmitted_expired_journeys = []

      Journeys::JOURNEYS
        .excluding(Journeys::FurtherEducationPayments)
        .each do |journey|
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

      PurgeUnsubmittedClaimsJob.new.perform

      expect(submitted_journeys.each(&:reload)).to all be_persisted

      expect(unsubmitted_fresh_journeys.each(&:reload)).to all be_persisted

      expect(
        Journeys::Session.where(id: unsubmitted_expired_journeys.map(&:id))
      ).to be_empty
    end

    context "when an EYTFI session with file attachments is purgeable" do
      it "deletes the session and purges its blobs from storage" do
        session = create(:eytfi_session, :with_employment_proof)
        session.update_column(:updated_at, over_24_hours_ago)

        expect {
          perform_enqueued_jobs { PurgeUnsubmittedClaimsJob.new.perform }
        }.to change(ActiveStorage::Blob, :count).by(-1)

        expect(Journeys::Session.where(id: session.id)).to be_empty
      end
    end

    context "FE sessions" do
      it "deletes unsubmitted sessions over a year old" do
        Journeys::FurtherEducationPayments::Session.create!(
          journey: Journeys::FurtherEducationPayments.routing_name,
          updated_at: 11.months.ago
        )

        expect {
          PurgeUnsubmittedClaimsJob.new.perform
        }.not_to change(Journeys::FurtherEducationPayments::Session, :count)

        Journeys::FurtherEducationPayments::Session.create!(
          journey: Journeys::FurtherEducationPayments.routing_name,
          updated_at: 13.months.ago
        )

        expect {
          PurgeUnsubmittedClaimsJob.new.perform
        }.to change(Journeys::FurtherEducationPayments::Session, :count).by(-1)
      end
    end
  end
end
