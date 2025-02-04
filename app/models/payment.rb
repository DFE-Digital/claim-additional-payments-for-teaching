class Payment < ApplicationRecord
  has_many :claim_payments, dependent: :destroy
  has_many :claims, through: :claim_payments
  has_many :topups, dependent: :nullify

  # When creating a payment for a topup both the topup and the topup's claim
  # are associated with the payment, so `Payment#claims` includes topup
  # claims, see PayrollRunJob#perform
  has_many(
    :non_topup_claims,
    ->(payment) { where.not(id: payment.topups.select(:claim_id)) },
    through: :claim_payments,
    source: :claim
  )

  belongs_to :payroll_run
  belongs_to :confirmation, class_name: "PaymentConfirmation", optional: true

  scope :ordered, -> { reorder(id: :asc) }
  scope :unconfirmed, -> { where(confirmation_id: nil) }

  validates :award_amount, presence: true

  validates :payroll_reference, :gross_value, :national_insurance, :employers_national_insurance, :tax, :net_pay, :gross_pay, presence: true, on: :upload
  validates :gross_value, :national_insurance, :employers_national_insurance, :student_loan_repayment, :tax, :net_pay, :gross_pay, numericality: true, allow_nil: true
  validates :scheduled_payment_date, presence: true, on: :upload
  validate :personal_details_must_be_consistent

  PERSONAL_CLAIM_DETAILS_ATTRIBUTES_PERMITTING_DISCREPANCIES = %i[
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
  ]
  PERSONAL_CLAIM_DETAILS_ATTRIBUTES_FORBIDDING_DISCREPANCIES = %i[
    date_of_birth
    student_loan_plan
    bank_sort_code
    bank_account_number
    building_society_roll_number
    national_insurance_number
  ]

  delegate(*(PERSONAL_CLAIM_DETAILS_ATTRIBUTES_PERMITTING_DISCREPANCIES + PERSONAL_CLAIM_DETAILS_ATTRIBUTES_FORBIDDING_DISCREPANCIES), to: :claim_for_personal_details)

  def policies_in_payment
    claims.map { |claim| claim.policy.payroll_file_name }.uniq.sort.join(" ")
  end

  def confirmed?
    confirmation.present?
  end

  private

  def personal_details_must_be_consistent
    mismatching_attributes = PERSONAL_CLAIM_DETAILS_ATTRIBUTES_FORBIDDING_DISCREPANCIES.select { |attribute|
      attribute_values = claims.map(&attribute)
      attribute_values.uniq.count > 1 && !attribute_values.all?(&:blank?)
    }

    if mismatching_attributes.any?
      claims_sentence = claims.map(&:reference).to_sentence
      attributes_list = mismatching_attributes.map { |attribute| Claim.human_attribute_name(attribute).downcase }
      attributes_sentence = attributes_list.to_sentence

      errors.add(:claims, "#{claims_sentence} have different values for #{attributes_sentence}")
    end
  end

  # NOTE: Optimisation - purposely not using .order(:submitted_at) causing N+1 queries
  def claim_for_personal_details
    @claim_for_personal_details ||= claims.max_by { |c| c.submitted_at } || topups.first.claim
  end
end
