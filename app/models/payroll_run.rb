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

  def self.create_with_claims!(claims, attrs = {})
    ActiveRecord::Base.transaction do
      PayrollRun.create!(attrs).tap do |payroll_run|
        claims.each do |claim|
          Payment.create!(payroll_run: payroll_run, claim: claim, award_amount: claim.award_amount)
        end
      end
    end
  end
end
