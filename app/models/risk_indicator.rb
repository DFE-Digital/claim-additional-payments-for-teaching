class RiskIndicator < ApplicationRecord
  SUPPORTED_FIELDS = %w[
    teacher_reference_number
    national_insurance_number
  ].freeze

  enum :field, SUPPORTED_FIELDS.index_by(&:itself)

  validates :value, presence: {
    message: "'value' can't be blank"
  }

  validates :value, uniqueness: {scope: :field}

  def self.flagged_attributes(claim)
    where(
      "field = 'national_insurance_number' AND LOWER(value) = :value",
      value: claim.national_insurance_number&.downcase
    ).or(
      where(
        field: "teacher_reference_number",
        value: claim.eligibility.try(:teacher_reference_number)
      )
    ).pluck(:field).compact
  end
end
