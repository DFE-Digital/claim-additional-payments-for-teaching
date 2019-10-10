class PayrollRun < ApplicationRecord
  has_many :claims

  validates :created_by, presence: true

  def total_award_amount
    claims.sum(&:award_amount)
  end

  def self.payrollable_claims
    Claim.approved.where(payroll_run: nil)
  end
end
