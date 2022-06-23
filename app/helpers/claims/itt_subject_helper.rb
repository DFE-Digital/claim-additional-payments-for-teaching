module Claims
  module IttSubjectHelper
    def subjects(trainee_teacher: nil, itt_academic_year: nil, ineligible_for_lup: nil)
      return %i[chemistry computing mathematics physics] if trainee_teacher

      case itt_academic_year
      when AcademicYear.new(2017), AcademicYear.new(2021)
        if ineligible_for_lup
          []
        else
          %i[chemistry computing mathematics physics]
        end
      when AcademicYear.new(2018), AcademicYear.new(2019)
        if ineligible_for_lup
          %i[mathematics]
        else
          %i[chemistry computing mathematics physics]
        end
      when AcademicYear.new(2020)
        if ineligible_for_lup
          %i[chemistry foreign_languages mathematics physics]
        else
          %i[chemistry computing foreign_languages mathematics physics]
        end
      end
    end

    def subjects_to_sentence(*args)
      subjects(*args).map { |sub| t("early_career_payments.answers.eligible_itt_subject.#{sub}") }
        .to_sentence(last_word_connector: " or ")
        .downcase
    end
  end
end
