class RiskIndicator < ApplicationRecord
  SUPPORTED_FIELDS = %w[
    teacher_reference_number
    national_insurance_number
  ].freeze

  validates :field, presence: {
    message: "'field' can't be blank"
  }

  validates :value, presence: {
    message: "'value' can't be blank"
  }

  validates :value, uniqueness: {scope: :field}

  validates :field,
    inclusion: {
      in: SUPPORTED_FIELDS,
      message: "'%{value}' is not a valid attribute - must be one of #{SUPPORTED_FIELDS.join(", ")}"
    }

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
