module LevellingUpPremiumPayments
  class Eligibility < ApplicationRecord
    self.table_name = "levelling_up_premium_payments_eligibilities"
    has_one :claim, as: :eligibility, inverse_of: :eligibility
    belongs_to :current_school, optional: true, class_name: "School"

    validates :award_amount, on: :amendment, award_range: {max: LevellingUpPremiumPayments::Award.max}

    def policy
      LevellingUpPremiumPayments
    end

    # maintains interface
    def ineligible?
    end
  end
end
