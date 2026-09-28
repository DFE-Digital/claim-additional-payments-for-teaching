require "rails_helper"

RSpec.describe Policies::DataRetention::RemoveRecoveryRecordsJob do
  describe "#perform" do
    let(:claim) { create(:claim) }

    context "when the recovery record is due to be destroyed" do
      it "deletes the record" do
        recovery = Policies::DataRetention::Recovery.create!(
          claim: claim,
          payload: [],
          destroy_at: Date.yesterday.end_of_day
        )

        travel_to(Date.today.beginning_of_day) do
          described_class.perform_now
        end

        expect { recovery.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when the recovery record is not due to be destroyed" do
      it "does not delete the record" do
        Policies::DataRetention::Recovery.create!(
          claim: claim,
          payload: [],
          destroy_at: Date.today.end_of_day
        )

        travel_to(Date.today.beginning_of_day) do
          described_class.perform_now
        end

        expect(Policies::DataRetention::Recovery.count).to be(1)
      end
    end
  end
end
