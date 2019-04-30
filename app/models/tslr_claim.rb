class TslrClaim < ApplicationRecord
  VALID_QTS_YEARS = [
    "2013-2014",
    "2014-2015",
    "2015-2016",
    "2016-2017",
    "2017-2018",
    "2018-2019",
    "2019-2020",
  ].freeze

  validates :qts_award_year, inclusion: {in: VALID_QTS_YEARS, message: "Select the academic year you were awarded qualified teacher status"}, on: :"qts-year"
end
