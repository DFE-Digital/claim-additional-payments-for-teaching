module GeckoboardHelpers
  # Use this to stub out the API calls that will be made to Geckoboard when a
  # Claim is submitted. It will return the webmock POST request, which can be
  # used to write expectations about the request being made.
  def stub_geckoboard_submitted_event
    stub_geckoboard_dataset_find_or_create("claims.submitted.test")
    stub_geckoboard_dataset_post("claims.submitted.test")
  end

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
