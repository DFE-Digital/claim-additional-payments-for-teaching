require "rails_helper"

RSpec.describe AnalyticsImporter do
  around do |example|
    travel_to DateTime.new(2024, 1, 1, 0, 0, 0) do
      perform_enqueued_jobs do
        example.run
      end
    end
  end

  let(:response) { double("response", success?: true) }
  let(:table) { double("table", insert: response) }
  let(:dataset) { double("dataset", table: table) }
  let(:bigquery) { double("bigquery", dataset: dataset) }

  before do
    allow(DfE::Analytics).to receive(:enabled?).and_return(true)
    allow(DfE::Analytics).to receive(:log_only?).and_return(false)

    DfE::Analytics.configure do |config|
      config.bigquery_project_id = "test-123"
      config.bigquery_table_name = "test_table"
      config.bigquery_dataset = "test_dataset"
      config.bigquery_api_json_key = '{ "type": "service_account" }'
    end

    allow(Google::Cloud::Bigquery).to receive(:new).and_return(bigquery)
  end

  describe ".import" do
    it "sends the entity information to dfe analytics" do
      claim = create(
        :claim,
        first_name: "Homer",
        middle_name: "J",
        surname: "Simpson",
        date_of_birth: Date.new(1956, 5, 12),
        policy: Policies::FurtherEducationPayments
      )

      AnalyticsImporter.import(Claim)

      expect(table).to have_received(:insert).with(
        [
          {
            "environment" => "test",
            "occurred_at" => "2024-01-01T00:00:00.000000+00:00",
            "event_type" => "import_entity",
            "entity_table_name" => "claims",
            "event_tags" => ["20240101000000"],
            "data" => a_hash_including({"key" => "id", "value" => [claim.id]}),
            "hidden_data" => [
              {
                "key" => "onelogin_uid",
                "value" => []
              },
              {
                "key" => "fe_first_name",
                "value" => ["Homer"]
              },
              {
                "key" => "fe_middle_name",
                "value" => ["J"]
              },
              {
                "key" => "fe_surname",
                "value" => ["Simpson"]
              },
              {
                "key" => "fe_date_of_birth",
                "value" => ["1956-05-12"]
              }
            ]
          }
        ],
        ignore_unknown: true
      )
    end
  end
end
