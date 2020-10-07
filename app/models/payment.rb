class Payment < ApplicationRecord
  has_many :claims, dependent: :nullify
  belongs_to :payroll_run

  validates :award_amount, presence: true

  validates :payroll_reference, :gross_value, :national_insurance, :employers_national_insurance, :tax, :net_pay, :gross_pay, presence: true, on: :upload
  validates :gross_value, :national_insurance, :employers_national_insurance, :student_loan_repayment, :tax, :net_pay, :gross_pay, numericality: true, allow_nil: true

  validate :personal_details_must_be_consistent

  PERSONAL_DETAILS_ATTRIBUTES_PERMITTING_DISCREPANCIES = %i[
    first_name
    middle_name
    surname
    payroll_gender
    email_address
    address_line_1
    address_line_2
    address_line_3
    address_line_4
    postcode
    has_student_loan
    banking_name
    national_insurance_number
  ]
  PERSONAL_DETAILS_ATTRIBUTES_FORBIDDING_DISCREPANCIES = %i[
    teacher_reference_number
    date_of_birth
    student_loan_plan
    bank_sort_code
    bank_account_number
    building_society_roll_number
  ]

  delegate(*(PERSONAL_DETAILS_ATTRIBUTES_PERMITTING_DISCREPANCIES + PERSONAL_DETAILS_ATTRIBUTES_FORBIDDING_DISCREPANCIES), to: :claim_for_personal_details)
  delegate :scheduled_payment_date, to: :payroll_run

  def policies_in_payment
    claims.map { |claim| claim.policy.to_s }.uniq.sort.join(" ")
  end

  private

  def personal_details_must_be_consistent
    mismatching_attributes = PERSONAL_DETAILS_ATTRIBUTES_FORBIDDING_DISCREPANCIES.select { |attribute|
      claims.map(&attribute).uniq.count > 1
    }

    if mismatching_attributes.any?
      claims_sentence = claims.map(&:reference).to_sentence
      attributes_sentence = mismatching_attributes.map { |attribute| Claim.human_attribute_name(attribute).downcase }.to_sentence
      errors.add(:claims, "#{claims_sentence} have different values for #{attributes_sentence}")
    end
  end

  def claim_for_personal_details
    @claim_for_personal_details ||= claims.order(:submitted_at).last
  end
end
