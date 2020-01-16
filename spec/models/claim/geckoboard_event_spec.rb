require "rails_helper"

RSpec.describe Claim::GeckoboardEvent, type: :model do
  let(:claim) { create(:claim, :submitted, created_at: DateTime.now) }
  let(:event_name) { "some_event" }

  it "sends the claim's reference, policy, along with the timestamp to the dataset indicated by the event name" do
    ClimateControl.modify ENVIRONMENT_NAME: "test" do
      event = Claim::GeckoboardEvent.new([claim], event_name, :created_at)

      dataset_post_stub = stub_geckoboard_dataset_update("claims.#{event_name}.test")

      event.record

      expect(dataset_post_stub.with { |request|
        request_body_matches_geckoboard_data_for_claims?(request, [claim], :created_at)
      }).to have_been_requested
    end
  end
end
