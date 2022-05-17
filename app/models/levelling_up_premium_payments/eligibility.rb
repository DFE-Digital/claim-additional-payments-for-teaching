module LevellingUpPremiumPayments
  class Eligibility < ApplicationRecord
    self.table_name = "levelling_up_premium_payments_eligibilities"
    has_one :claim, as: :eligibility, inverse_of: :eligibility
    belongs_to :current_school, optional: true, class_name: "School"

    validates :award_amount, on: :amendment, award_range: {max: LevellingUpPremiumPayments::Award.max}

    def policy
      LevellingUpPremiumPayments
    end

    def ineligible?
    end

    # allows wider range of input formats like ECP (and student_loan_repayment_amount in TSLR) does
    # (this is a copy of that code for now)
    def award_amount=(value)
      super(value.to_s.gsub(/[£,\s]/, ""))
    end
  end
end
