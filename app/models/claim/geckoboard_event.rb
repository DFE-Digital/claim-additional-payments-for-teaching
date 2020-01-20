require "geckoboard"

class Claim
  class GeckoboardEvent
    attr_reader :claims, :event_type, :performed_at_method

    DATASET_FIELDS = [
      Geckoboard::StringField.new(:reference, name: "Reference"),
      Geckoboard::StringField.new(:policy, name: "Policy"),
      Geckoboard::DateTimeField.new(:performed_at, name: "Performed at"),
    ]
    BATCH_SIZE = 500

    def initialize(claim_or_claims, event_type, performed_at_method)
      @claims = Array(claim_or_claims)
      @event_type = event_type
      @performed_at_method = performed_at_method
    end

    def record
      batched_claims.each do |batch|
        dataset.post(data_for_claims(batch))
      end
    end

    private

    def data_for_claims(claims)
      claims.map do |claim|
        {
          reference: claim.reference,
          policy: claim.policy.to_s,
          performed_at: claim.public_send(performed_at_method),
        }
      end
    end

    def client
      @client ||= Geckoboard.client(ENV.fetch("GECKOBOARD_API_KEY"))
    end

    def dataset
      @dataset ||= client.datasets.find_or_create(dataset_name, fields: DATASET_FIELDS)
    end

    def dataset_name
      [
        "claims",
        event_type,
        ENV.fetch("ENVIRONMENT_NAME"),
      ].join(".")
    end

    def batched_claims
      claims.each_slice(BATCH_SIZE).to_a
    end
  end
end
