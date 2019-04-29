module ClaimsHelper
  def options_for_qts_award_year
    TslrClaim::VALID_QTS_YEARS.map do |academic_years|
      start_year, end_year = academic_years.split("-")
      ["September 1 #{start_year} - August 31 #{end_year}", academic_years]
    end
  end
end
