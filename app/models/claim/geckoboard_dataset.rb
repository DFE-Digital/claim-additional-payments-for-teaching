require "geckoboard"

class Claim
  class GeckoboardDataset
    attr_reader :claims

    DATASET_FIELDS = [
      Geckoboard::StringField.new(:reference, name: "Reference"),
      Geckoboard::StringField.new(:policy, name: "Policy"),
      Geckoboard::DateTimeField.new(:submitted_at, name: "Submitted at"),
      Geckoboard::StringField.new(:passed_checking_deadline, name: "Passed checking deadline"),
      Geckoboard::StringField.new(:checked, name: "Checked"),
      Geckoboard::DateTimeField.new(:checked_at, name: "Checked at"),
      Geckoboard::StringField.new(:check_result, name: "Check result"),
      Geckoboard::NumberField.new(:number_of_days_to_check, name: "Number of days to check", optional: true),
      Geckoboard::StringField.new(:paid, name: "Paid"),
      Geckoboard::DateTimeField.new(:paid_at, name: "Paid at"),
    ]
    BATCH_SIZE = 500

    def initialize(claims: [])
      @claims = claims
    end

    def save
      batched_claims.each do |batch|
        dataset.post(data_for_claims(batch))
      end
    end

    def delete
      client.datasets.delete(dataset_name)
    end

    private

    def data_for_claims(claims)
      claims.map do |claim|
        {
          reference: claim.reference,
          policy: claim.policy.to_s,
          submitted_at: claim.submitted_at,
          passed_checking_deadline: claim.check_deadline_date.past?.to_s,
          checked: claim.check.present?.to_s,
          checked_at: claim.check.present? ? claim.check.created_at : placeholder_date_for_nil_value,
          check_result: claim.check.present? ? claim.check.result : "",
          number_of_days_to_check: claim.check&.number_of_days_since_claim_submitted,
          paid: claim.scheduled_payment_date.present?.to_s,
          paid_at: claim.scheduled_payment_date.presence || placeholder_date_for_nil_value,
        }
      end
    end

    def client
      @client ||= Geckoboard.client(ENV.fetch("GECKOBOARD_API_KEY"))
    end

    def dataset
      @dataset ||= client.datasets.find_or_create(dataset_name,
        fields: DATASET_FIELDS,
        unique_by: [:reference])
    end

    def dataset_name
      [
        "claims",
        ENV.fetch("ENVIRONMENT_NAME"),
      ].join(".")
    end

    def batched_claims
      claims.each_slice(BATCH_SIZE).to_a
    end

    def placeholder_date_for_nil_value
      DateTime.parse("1970-01-01")
    end
  end
end
