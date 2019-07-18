# frozen_string_literal: true

# Represents the year a teacher can qualify in

class QtsYears
  ELIGIBLE_YEARS = [
    "2013-2014",
    "2014-2015",
    "2015-2016",
    "2016-2017",
    "2017-2018",
    "2018-2019",
    "2019-2020",
  ].freeze

  class << self
    def first_eligible_year
      ELIGIBLE_YEARS.first.split("-").first
    end

    def option_values
      ELIGIBLE_YEARS.dup.unshift("before_#{QtsYears.first_eligible_year}")
    end

    def eligible?(years)
      ELIGIBLE_YEARS.include?(years)
    end
  end
end
