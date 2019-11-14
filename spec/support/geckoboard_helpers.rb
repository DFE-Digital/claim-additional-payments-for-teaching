module GeckoboardHelpers
  def stub_geckoboard_dataset_find_or_create(dataset_id)
    dataset_fields = {
      reference: {
        name: "Reference",
        type: "string",
      },
      policy: {
        name: "Policy",
        type: "string",
      },
      submitted_at: {
        name: "Date Submitted",
        type: "datetime",
      },
    }

    stub_request(:put, "https://api.geckoboard.com/datasets/#{dataset_id}")
      .with(
        body: {
          fields: dataset_fields,
        }.to_json
      )
      .to_return(status: 200, body: {
        id: dataset_id,
        fields: dataset_fields,
        unique_by: ["timestamp"],
      }.to_json)
  end

  def stub_geckoboard_dataset_post(dataset_id)
    stub_request(:post, "https://api.geckoboard.com/datasets/#{dataset_id}/data")
  end
end
