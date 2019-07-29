# frozen_string_literal: true

module StudentLoans
  class Eligibility < ApplicationRecord
    self.table_name = "student_loans_eligibilities"

    enum qts_award_year: {
      "before_2013": 0,
      "2013_2014": 1,
      "2014_2015": 2,
      "2015_2016": 3,
      "2016_2017": 4,
      "2017_2018": 5,
      "2018_2019": 6,
      "2019_2020": 7,
    }, _prefix: :awarded_qualified_status

    validates :qts_award_year, on: [:"qts-year", :submit], presence: {message: "Select the academic year you were awarded qualified teacher status"}

    def ineligible?
      ineligible_qts_award_year?
    end

    private

    def ineligible_qts_award_year?
      awarded_qualified_status_before_2013?
    end
  end
end
