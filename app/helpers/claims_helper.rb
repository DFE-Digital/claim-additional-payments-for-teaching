module ClaimsHelper
  def options_for_qts_award_year
    TslrClaim::VALID_QTS_YEARS.map { |year_range| [academic_years(year_range), year_range] }
  end

  def tslr_claim_ineligibility_reason(claim)
    case claim.ineligibility_reason
    when :ineligible_claim_school then "#{claim.claim_school_name} is not an eligible school."
    when :employed_at_no_school then "You must be still working as a teacher to be eligible."
    when :not_taught_eligible_subjects_enough then "You must have spent at least half your time teaching an eligible subject."
    else "You can only apply for this payment if you meet the eligibility criteria."
    end
  end

  def tslr_guidance_url
    "https://www.gov.uk/guidance/teachers-student-loan-reimbursement-guidance-for-teachers-and-schools"
  end

  def claim_timeout_in_minutes
    ClaimsController::TIMEOUT_LENGTH_IN_MINUTES
  end

  private

  def academic_years(year_range)
    start_year, end_year = year_range.split("-")

    "September 1 #{start_year} - August 31 #{end_year}"
  end
end
