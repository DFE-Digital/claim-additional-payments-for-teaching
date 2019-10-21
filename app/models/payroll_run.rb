class PayrollRun < ApplicationRecord
  has_many :payments
  has_many :claims, through: :payments

  validates :created_by, presence: true

  def total_award_amount
    claims.sum(&:award_amount)
  end

  def self.payrollable_claims
    Claim.approved.left_joins(:payment).where(payments: {id: nil})
  end
end
