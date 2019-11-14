require "geckoboard"

class Claim
  class GeckoboardEvent
    attr_reader :claim, :event_type, :performed_at

    DATASET_FIELDS = [
      Geckoboard::StringField.new(:reference, name: "Reference"),
      Geckoboard::StringField.new(:policy, name: "Policy"),
      Geckoboard::DateTimeField.new(:performed_at, name: "Performed at"),
    ]

    def initialize(claim, event_type, performed_at)
      @claim = claim
      @event_type = event_type
      @performed_at = performed_at
    end

    def record
      dataset.post([data])
    end

    private

    def data
      {
        reference: claim.reference,
        policy: claim.policy.to_s,
        performed_at: performed_at,
      }
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
