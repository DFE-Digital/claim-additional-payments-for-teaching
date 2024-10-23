class StudentLoansData < ApplicationRecord
  def self.repaying_plan_types
    pluck(:plan_type_of_deduction).uniq.sort.join("_and_").presence&.prepend("plan_")
  end

  def self.total_repayment_amount
    distinct_entries = select(:nino, :date_of_birth, :plan_type_of_deduction, :amount).distinct
    distinct_entries.sum(:amount)
  end
end
