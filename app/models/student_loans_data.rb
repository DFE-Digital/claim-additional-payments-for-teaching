class StudentLoansData < ApplicationRecord
  scope :by_nino, ->(nino) do
    where(nino: nino).extending do
      def repaying_plan_types
        pluck(:plan_type_of_deduction).uniq.sort.join("_and_").presence&.prepend("plan_")
      end

      def total_repayment_amount
        sum(:amount)
      end
    end
  end
end
