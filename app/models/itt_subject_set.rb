# frozen_string_literal: true

class IttSubjectSet
  def self.from_current_claim(current_claim)
    lup_claim_eligibility = current_claim.for_policy(LevellingUpPremiumPayments).eligibility

    trainee_teacher = !lup_claim_eligibility.nqt_in_academic_year_after_itt
    itt_academic_year = lup_claim_eligibility.itt_academic_year
    ineligible_for_lup = lup_claim_eligibility.ineligible?

    new(trainee_teacher: trainee_teacher, itt_academic_year: itt_academic_year, ineligible_for_lup: ineligible_for_lup)
  end

  def initialize(trainee_teacher: nil, itt_academic_year: nil, ineligible_for_lup: nil)
    @trainee_teacher = trainee_teacher
    @itt_academic_year = itt_academic_year
    @ineligible_for_lup = ineligible_for_lup
  end

  def subjects
    return %i[chemistry computing mathematics physics] if @trainee_teacher

    case @itt_academic_year
    when AcademicYear.new(2017), AcademicYear.new(2021)
      if @ineligible_for_lup
        []
      else
        %i[chemistry computing mathematics physics]
      end
    when AcademicYear.new(2018), AcademicYear.new(2019)
      if @ineligible_for_lup
        %i[mathematics]
      else
        %i[chemistry computing mathematics physics]
      end
    when AcademicYear.new(2020)
      if @ineligible_for_lup
        %i[chemistry foreign_languages mathematics physics]
      else
        %i[chemistry computing foreign_languages mathematics physics]
      end
    end
  end
end
