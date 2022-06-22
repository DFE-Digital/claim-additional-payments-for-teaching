module LevellingUpPremiumPayments
  class Eligibility < ApplicationRecord
    self.table_name = "levelling_up_premium_payments_eligibilities"
    has_one :claim, as: :eligibility, inverse_of: :eligibility
    belongs_to :current_school, optional: true, class_name: "School"

    # TODO: use first year of LUP for now but this must come from a PolicyConfiguration
    validates :award_amount, on: :amendment, award_range: {max: LevellingUpPremiumPayments::Award.max(AcademicYear.new(2022))}
    validates :eligible_degree_subject, on: [:"eligible-degree-subject"], inclusion: {in: [true, false], message: "Select yes if you have a degree in an eligible subject"}

    EDITABLE_ATTRIBUTES = [
      :nqt_in_academic_year_after_itt,
      :current_school_id,
      :employed_as_supply_teacher,
      :has_entire_term_contract,
      :employed_directly,
      :subject_to_formal_performance_action,
      :subject_to_disciplinary_action,
      :qualification,
      :eligible_itt_subject,
      :teaching_subject_now,
      :itt_academic_year,
      :eligible_degree_subject
    ].freeze

    AMENDABLE_ATTRIBUTES = [:award_amount].freeze

    ATTRIBUTE_DEPENDENCIES = {
      "employed_as_supply_teacher" => ["has_entire_term_contract", "employed_directly"],
      "qualification" => ["eligible_itt_subject", "teaching_subject_now"],
      "eligible_itt_subject" => ["teaching_subject_now", "eligible_degree_subject"],
      "itt_academic_year" => ["eligible_itt_subject"]
    }.freeze

    enum qualification: {
      postgraduate_itt: 0,
      undergraduate_itt: 1,
      assessment_only: 2,
      overseas_recognition: 3
    }

    enum eligible_itt_subject: {
      chemistry: 0,
      foreign_languages: 1,
      mathematics: 2,
      physics: 3,
      none_of_the_above: 4,
      computing: 5
    }, _prefix: :itt_subject

    # TODO this is *inadequate* for future policy years
    # Whatever the current policy year is, a teacher should be able to
    # choose from the previous five academic years. To cover the life
    # of LUP, this needs to be from 2017/2018 to 2023/2024 (inclusive) but remember
    # only the previous five should ever be selectable (and valid) for the
    # current policy year.
    #
    # You can get the previous five academic years for display (and validation) from
    # the `JourneySubjectEligibilityChecker#selectable_itt_years` method
    enum itt_academic_year: {
      AcademicYear.new(2017) => AcademicYear::Type.new.serialize(AcademicYear.new(2017)),
      AcademicYear.new(2018) => AcademicYear::Type.new.serialize(AcademicYear.new(2018)),
      AcademicYear.new(2019) => AcademicYear::Type.new.serialize(AcademicYear.new(2019)),
      AcademicYear.new(2020) => AcademicYear::Type.new.serialize(AcademicYear.new(2020)),
      AcademicYear.new(2021) => AcademicYear::Type.new.serialize(AcademicYear.new(2021)),
      AcademicYear.new => AcademicYear::Type.new.serialize(AcademicYear.new)
    }

    before_save :set_qualification_if_trainee_teacher, if: :nqt_in_academic_year_after_itt_changed?

    def policy
      LevellingUpPremiumPayments
    end

    def ineligible?
      trainee_teacher_with_itt_subject_none_of_the_above ||
        has_ineligible_school? ||
        no_entire_term_contract? ||
        not_employed_directly? ||
        poor_performance? ||
        has_bad_itt_subject_and_no_relevant_degree? ||
        with_eligible_degree_subject_not_teaching_subject_now? ||
        ineligible_cohort?
    end

    def eligible_now?
      !ineligible?
    end

    def eligible_later?
      final_lup_policy_year = AcademicYear.new(2024)

      if PolicyConfiguration.for(LevellingUpPremiumPayments).current_academic_year < final_lup_policy_year
        # it'll be the same as now because the LUP set of valid subjects is meant to stay constant
        eligible_now?
      else
        # there is no LUP policy year after this
        false
      end
    end

    def award_amount
      super || calculate_award_amount
    end

    def reset_dependent_answers(reset_attrs = [])
      attrs = ineligible? ? changed.concat(reset_attrs) : changed

      ATTRIBUTE_DEPENDENCIES.each do |attribute_name, dependent_attribute_names|
        dependent_attribute_names.each do |dependent_attribute_name|
          write_attribute(dependent_attribute_name, nil) if attrs.include?(attribute_name)
        end
      end
    end

    def has_indicated_a_bad_itt_subject?
      !eligible_itt_subject.nil? and !eligible_itt_subject.to_sym.in?([:chemistry, :computing, :mathematics, :physics])
    end

    def submit!
      self.award_amount = award_amount
      save!
    end

    private

    def has_bad_itt_subject_and_no_relevant_degree?
      has_indicated_a_bad_itt_subject? and has_indicated_they_lack_eligible_degree?
    end

    def has_ineligible_school?
      current_school.present? and !LevellingUpPremiumPayments::SchoolEligibility.new(current_school).eligible?
    end

    def calculate_award_amount
      # TODO: use first year of LUP for now but this must come from a PolicyConfiguration
      BigDecimal LevellingUpPremiumPayments::Award.new(school: current_school, year: AcademicYear.new(2022)).amount_in_pounds if current_school.present?
    end

    def with_eligible_degree_subject_not_teaching_subject_now?
      has_indicated_a_bad_itt_subject? && eligible_degree_subject && not_teaching_subject_now?
    end

    def not_teaching_subject_now?
      teaching_subject_now == false
    end

    def has_indicated_they_lack_eligible_degree?
      eligible_degree_subject == false
    end

    # Start LUP duplicates

    def trainee_teacher?
      nqt_in_academic_year_after_itt == false
    end

    def no_entire_term_contract?
      employed_as_supply_teacher? && has_entire_term_contract == false
    end

    def not_employed_directly?
      employed_as_supply_teacher? && employed_directly == false
    end

    def poor_performance?
      subject_to_formal_performance_action? ||
        subject_to_disciplinary_action?
    end

    def ineligible_cohort?
      itt_academic_year == AcademicYear.new # `None of the above` selected
    end

    def set_qualification_if_trainee_teacher
      return unless trainee_teacher?

      self.qualification = :postgraduate_itt
    end

    def trainee_teacher_with_itt_subject_none_of_the_above
      trainee_teacher? && itt_subject_none_of_the_above?
    end
  end
end
