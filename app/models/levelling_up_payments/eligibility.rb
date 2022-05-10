module LevellingUpPayments
  class Eligibility < ApplicationRecord
    self.table_name = "levelling_up_payments_eligibilities"
    has_one :claim, as: :eligibility, inverse_of: :eligibility
  end
end
