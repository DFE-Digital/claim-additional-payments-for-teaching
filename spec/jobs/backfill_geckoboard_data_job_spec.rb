require "rails_helper"
require "geckoboard"

RSpec.describe BackfillGeckoboardDataJob do
  let(:claims) { build_list(:claim, 5, :submitted) }

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

  subject { described_class.new }

  it "sends the expected data to the endpoint specified by the event name" do
    ClimateControl.modify ENVIRONMENT_NAME: "environment_name" do
      stub_geckoboard_dataset_find_or_create("claims.some_event.environment_name")

      dataset_post_stub = stub_geckoboard_dataset_post("claims.some_event.environment_name")

      subject.perform(event_name, data)

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
