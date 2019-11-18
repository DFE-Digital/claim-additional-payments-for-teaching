require "rails_helper"

RSpec.describe Claim::BulkGeckoboardEvent, type: :model do
  let(:claims) { build_list(:claim, 4, :submitted) }

  let(:datetime) { DateTime.now }
  let(:event_name) { "some_event" }

  let(:data) do
    claims.map do |claim|
      {
        reference: claim.reference,
        policy: claim.policy.to_s,
        performed_at: datetime,
      }
    end
  end

  it "sends the expected data to the endpoint specified by the event name" do
    ClimateControl.modify ENVIRONMENT_NAME: "test" do
      event = Claim::BulkGeckoboardEvent.new(event_name, data)

      stub_geckoboard_dataset_find_or_create("claims.#{event_name}.test")
      dataset_post_stub = stub_geckoboard_dataset_post("claims.#{event_name}.test")

      event.record

      expected_data_payload = claims.map { |claim|
        {
          reference: claim.reference,
          policy: claim.policy.to_s,
          performed_at: datetime.strftime("%Y-%m-%dT%H:%M:%S%:z"),
        }
      }

      expect(dataset_post_stub.with(body: {data: expected_data_payload})).to have_been_requested
    end
  end
end
