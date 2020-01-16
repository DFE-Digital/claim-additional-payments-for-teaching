require "geckoboard"

class Claim
  class GeckoboardEvent
    attr_reader :claims, :event_type, :performed_at_method

    DATASET_FIELDS = [
      Geckoboard::StringField.new(:reference, name: "Reference"),
      Geckoboard::StringField.new(:policy, name: "Policy"),
      Geckoboard::DateTimeField.new(:performed_at, name: "Performed at"),
    ]

    def initialize(claim_or_claims, event_type, performed_at_method)
      @claims = Array(claim_or_claims)
      @event_type = event_type
      @performed_at_method = performed_at_method
    end

    def record
      dataset.post(data)
    end

    private

    def data
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
      client.datasets.find_or_create(dataset_name, fields: DATASET_FIELDS)
    end

    def dataset_name
      [
        "claims",
        event_type,
        ENV.fetch("ENVIRONMENT_NAME"),
      ].join(".")
    end
  end
end
