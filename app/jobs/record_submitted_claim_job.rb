require "geckoboard"

class RecordSubmittedClaimJob < ApplicationJob
  def perform(claim)
    append_data({
      reference: claim.reference,
      policy: claim.policy.to_s,
      submitted_at: claim.submitted_at,
    })
  end

  def append_data(data)
    dataset.post([data])
  end

  def client
    @client ||= Geckoboard.client(ENV.fetch("GECKOBOARD_API_KEY"))
  end

  def dataset
    client.datasets.find_or_create(dataset_name, fields: fields)
  end

  def dataset_name
    "claims.submitted.#{ENV.fetch("ENVIRONMENT_NAME")}"
  end

  def fields
    @fields ||= [
      Geckoboard::StringField.new(:reference, name: "Reference"),
      Geckoboard::StringField.new(:policy, name: "Policy"),
      Geckoboard::DateTimeField.new(:submitted_at, name: "Date Submitted"),
    ]
  end
end
