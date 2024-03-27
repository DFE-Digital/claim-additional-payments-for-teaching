class StudentLoansData < ApplicationRecord
  def self.repaying_plan_types
    pluck(:plan_type_of_deduction).uniq.sort.join("_and_").presence&.prepend("plan_")
  end

  def self.total_repayment_amount
    sum(:amount)
  end
end
