class ClaimantFlag < ApplicationRecord
  IDENTIFICATION_ATTRIBUTES = %w[national_insurance_number].freeze

  belongs_to :previous_claim, class_name: "Claim", optional: true

  enum :reason, %w[clawback].index_by(&:itself)

  normalizes :identification_value, with: ->(idv) { idv.strip.downcase }

  validates :identification_attribute, presence: true
  validates :identification_attribute, inclusion: {
    in: %w[national_insurance_number]
  }
  validates :identification_value, presence: true
  validates :reason, presence: true
  validates :reason, inclusion: {
    in: %w[clawback]
  }
  validates :policy, inclusion: {in: Policies.all.map(&:to_s)}

  scope :for_policy, ->(policy) { where(policy: policy.to_s) }

  scope :for_national_insurance_number, ->(national_insurance_number) do
    where(
      identification_attribute: "national_insurance_number",
      identification_value: national_insurance_number.to_s.strip.downcase
    )
  end

  def self.for(claim)
    for_policy(claim.policy)
      .for_national_insurance_number(claim.national_insurance_number)
  end
end
