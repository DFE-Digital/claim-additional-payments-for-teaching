require "rails_helper"

RSpec.describe RecordClaimEventJob do
  let(:claims) { create_list(:claim, 5, :submitted) }

  subject { described_class.new }

  it "sends each claim's reference, policy and submitted date to the specified dataset" do
    event_type = "submitted"
    environment_name = "environment_name"
    dataset = "claims.#{event_type}.#{environment_name}"

    ClimateControl.modify ENVIRONMENT_NAME: environment_name do
      dataset_post_stub = stub_geckoboard_dataset_update(dataset)

      subject.perform(claims.pluck(:id), event_type, :submitted_at)

      expect(dataset_post_stub.with { |request|
        request_body_matches_geckoboard_data_for_claims?(request, claims, :submitted_at)
      }).to have_been_requested
    end
  end
end
