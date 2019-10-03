class PayrollRun < ApplicationRecord
  has_many :claims

  validates :created_by, presence: true

  def total_award_amount
    claims.sum(&:award_amount)
  end
end
