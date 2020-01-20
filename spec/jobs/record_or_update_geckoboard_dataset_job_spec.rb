require "rails_helper"

RSpec.describe RecordOrUpdateGeckoboardDatasetJob do
  let(:claims) { create_list(:claim, 5, :submitted) }

  subject { described_class.new }

  it "sends each claim to the specified dataset" do
    environment_name = "environment_name"
    dataset = "claims.#{environment_name}"

    ClimateControl.modify ENVIRONMENT_NAME: environment_name do
      dataset_post_stub = stub_geckoboard_dataset_update(dataset)

      subject.perform(claims.pluck(:id))

      expect(dataset_post_stub.with { |request|
        request_body_matches_geckoboard_data_for_claims?(request, claims)
      }).to have_been_requested
    end
  end
end
