module EarlyCareerPayments
  class Eligibility < ApplicationRecord
    EDITABLE_ATTRIBUTES = [
      :nqt_in_academic_year_after_itt,
      :employed_as_supply_teacher
    ].freeze
    AMENDABLE_ATTRIBUTES = [].freeze

    self.table_name = "early_career_payments_eligibilities"

    has_one :claim, as: :eligibility, inverse_of: :eligibility

    validates :nqt_in_academic_year_after_itt, on: [:"nqt-in-academic-year-after-itt", :submit], inclusion: {in: [true, false], message: "Select yes if you did your NQT in the academic year after your ITT"}
    validates :employed_as_supply_teacher, on: [:"supply-teacher", :submit], inclusion: {in: [true, false], message: "Select yes if you are currently employed as a supply teacher"}

    def policy
      EarlyCareerPayments
    end

    def ineligible?
      ineligible_nqt_in_academic_year_after_itt? ||
        not_employed_directly?
    end

    def award_amount
      BigDecimal("2000.00")
    end

    private

    def ineligible_nqt_in_academic_year_after_itt?
      nqt_in_academic_year_after_itt == false
    end

    def not_employed_directly?
      employed_as_supply_teacher == true
    end
  end
end
