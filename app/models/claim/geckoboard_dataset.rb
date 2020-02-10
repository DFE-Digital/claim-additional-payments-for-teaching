require "geckoboard"

class Claim
  class GeckoboardDataset
    attr_reader :claims

    # If any change is made to the `DATASET_FIELDS` constant below, it's important
    # to run the `rake geckoboard:reset` task.
    # See https://github.com/DFE-Digital/dfe-teachers-payment-service#geckoboard for more
    # detail
    DATASET_FIELDS = [
      Geckoboard::StringField.new(:reference, name: "Reference"),
      Geckoboard::StringField.new(:policy, name: "Policy"),
      Geckoboard::DateTimeField.new(:submitted_at, name: "Submitted at"),
      Geckoboard::StringField.new(:sla_status, name: "SLA status"),
      Geckoboard::StringField.new(:check, name: "Check"),
      Geckoboard::DateTimeField.new(:checked_at, name: "Checked at"),
      Geckoboard::NumberField.new(:number_of_days_to_check, name: "Number of days to check", optional: true),
      Geckoboard::StringField.new(:paid, name: "Paid"),
      Geckoboard::DateTimeField.new(:paid_at, name: "Paid at"),
      Geckoboard::MoneyField.new(:award_amount, name: "Award amount", optional: true, currency_code: "GBP"),
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

    def data_for_claims(claims)
      claims.map do |claim|
        {
          reference: claim.reference,
          policy: claim.policy.to_s,
          submitted_at: claim.submitted_at,
          sla_status: sla_status_string(claim),
          check: claim.decision.present? ? claim.decision.result : "unchecked",
          checked_at: claim.decision.present? ? claim.decision.created_at : placeholder_date_for_nil_value,
          number_of_days_to_check: claim.decision&.number_of_days_since_claim_submitted,
          paid: claim.scheduled_payment_date.present?.to_s,
          paid_at: claim.scheduled_payment_date.presence || placeholder_date_for_nil_value,
          award_amount: claim.eligibility.present? ? (claim.award_amount * 100).to_i : nil, # Geckoboard expects currency as an integer of pence - see https://api-docs.geckoboard.com/#money-format
        }
      end
    end

    private

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

    def sla_status_string(claim)
      if claim.check_deadline_date.past?
        "passed"
      elsif claim.deadline_warning_date.past?
        "warning"
      else
        "ok"
      end
    end
  end
end
