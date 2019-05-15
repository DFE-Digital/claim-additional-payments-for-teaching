module ClaimsHelper
  def options_for_qts_award_year
    TslrClaim::VALID_QTS_YEARS.map do |academic_years|
      start_year, end_year = academic_years.split("-")
      ["September 1 #{start_year} - August 31 #{end_year}", academic_years]
    end
  end

  def tslr_claim_ineligibility_reason(claim)
    case claim.ineligibility_reason
    when :ineligible_claim_school then "#{claim.claim_school_name} is not an eligible school."
    when :employed_at_no_school then "You must be still working as a teacher to be eligible."
    else "You can only apply for this payment if you meet the eligibility criteria."
    end
  end

  def tslr_guidance_url
    "https://www.gov.uk/guidance/teachers-student-loan-reimbursement-guidance-for-teachers-and-schools"
  end
end
