# a Cohort represent an abstract mechanism to group academic years
class Cohort
  attr_reader :claim

  def initialize(claim:)
    @claim = claim
  end

  def academic_years
    case claim.policy
    when Policies::EarlyYearsTeachersFinancialIncentivePayments
      if [AcademicYear.new(2025), AcademicYear.new(2026)].include?(claim.academic_year)
        [AcademicYear.new(2025), AcademicYear.new(2026)]
      else
        [claim.academic_year]
      end
    else
      [claim.academic_year]
    end
  end
end
