module MathsAndPhysics
  class Eligibility < ApplicationRecord
    EDITABLE_ATTRIBUTES = [
      :teaching_maths_or_physics,
      :current_school_id,
      :initial_teacher_training_subject,
      :initial_teacher_training_subject_specialism,
      :has_uk_maths_or_physics_degree,
      :qts_award_year,
      :employed_as_supply_teacher,
      :has_entire_term_contract,
      :employed_directly,
      :subject_to_disciplinary_action,
      :subject_to_formal_performance_action
    ].freeze
    AMENDABLE_ATTRIBUTES = [].freeze
    ATTRIBUTE_DEPENDENCIES = {
      "initial_teacher_training_subject" => ["initial_teacher_training_subject_specialism", "has_uk_maths_or_physics_degree"],
      "initial_teacher_training_subject_specialism" => ["has_uk_maths_or_physics_degree"],
      "employed_as_supply_teacher" => ["has_entire_term_contract", "employed_directly"]
    }.freeze
    self.table_name = "maths_and_physics_eligibilities"

    enum initial_teacher_training_subject: {
      maths: 0,
      physics: 1,
      science: 2,
      none_of_the_subjects: 3
    }, _prefix: :itt_subject

    enum initial_teacher_training_subject_specialism: {
      physics: 0,
      biology: 1,
      chemistry: 2,
      not_sure: 3
    }, _prefix: :itt_specialism

    enum has_uk_maths_or_physics_degree: {
      yes: 0,
      no: 1,
      has_non_uk: 2
    }

    enum qts_award_year: {
      before_cut_off_date: 0,
      on_or_after_cut_off_date: 1
    }, _prefix: :awarded_qualified_status

    has_one :claim, as: :eligibility, inverse_of: :eligibility
    belongs_to :current_school, optional: true, class_name: "School"

    validates :teaching_maths_or_physics, on: [:"teaching-maths-or-physics", :submit], inclusion: {in: [true, false], message: "Select yes if you teach any maths or physics"}
    validates :current_school, on: [:"current-school", :submit], presence: {message: "Select a school from the list or search again for a different school"}
    validates :initial_teacher_training_subject, on: [:"initial-teacher-training-subject", :submit], presence: {message: "Select if you completed your initial teacher training in Maths, Physics, Science, or None of these subjects"}
    validates :initial_teacher_training_subject_specialism, on: [:"initial-teacher-training-subject-specialism", :submit], presence: {message: "Select the subject your initial teacher training specialised in or select I'm not sure"}, if: :itt_subject_science?
    validates :has_uk_maths_or_physics_degree, on: [:"has-uk-maths-or-physics-degree", :submit], presence: {message: "Select yes if you have a UK degree specialising in maths or physics"}, unless: :initial_teacher_training_specialised_in_maths_or_physics?
    validates :qts_award_year, on: [:"qts-year", :submit], presence: {message: "Select when you completed your initial teacher training"}
    validates :employed_as_supply_teacher, on: [:"supply-teacher", :submit], inclusion: {in: [true, false], message: "Select yes if you are currently employed as a supply teacher"}
    validates :has_entire_term_contract, on: [:"entire-term-contract", :submit], inclusion: {in: [true, false], message: "Select yes if you have a contract to teach at the same school for one term or longer"}, if: :employed_as_supply_teacher?
    validates :employed_directly, on: [:"employed-directly", :submit], inclusion: {in: [true, false], message: "Select yes if you are employed directly by your school"}, if: :employed_as_supply_teacher?
    validates :subject_to_disciplinary_action, on: [:"disciplinary-action", :submit], inclusion: {in: [true, false], message: "Select yes if you are subject to disciplinary action"}
    validates :subject_to_formal_performance_action, on: [:"formal-performance-action", :submit], inclusion: {in: [true, false], message: "Select yes if you are subject to formal action for poor performance at work"}

    delegate :name, to: :current_school, prefix: true, allow_nil: true
    delegate :academic_year, to: :claim, prefix: true

    def policy
      MathsAndPhysics
    end

    def ineligible?
      not_teaching_maths_or_physics? ||
        ineligible_current_school? ||
        no_maths_or_physics_qualification? ||
        ineligible_qts_award_year? ||
        no_entire_term_contract? ||
        not_employed_directly? ||
        subject_to_disciplinary_action? ||
        subject_to_formal_performance_action?
    end

    def ineligibility_reason
      [
        :not_teaching_maths_or_physics,
        :ineligible_current_school,
        :no_maths_or_physics_qualification,
        :ineligible_qts_award_year,
        :no_entire_term_contract,
        :not_employed_directly,
        :subject_to_disciplinary_action,
        :subject_to_formal_performance_action
      ].find { |eligibility_check| send("#{eligibility_check}?") }
    end

    def award_amount
      BigDecimal("2000.00")
    end

    def reset_dependent_answers
      ATTRIBUTE_DEPENDENCIES.each do |attribute_name, dependent_attribute_names|
        dependent_attribute_names.each do |dependent_attribute_name|
          write_attribute(dependent_attribute_name, nil) if changed.include?(attribute_name)
        end
      end
    end

    def eligible_itt_subject
    end

    def initial_teacher_training_specialised_in_maths_or_physics?
      itt_subject_maths? || itt_subject_physics? || itt_specialism_physics?
    end

    # Returns a String that is the human-readable answer given for the QTS
    # question when the claim was made.
    def qts_award_year_answer
      year_for_answer = MathsAndPhysics.first_eligible_qts_award_year(claim_academic_year)
      year_for_answer -= 1 if awarded_qualified_status_before_cut_off_date?

      I18n.t("answers.qts_award_years.#{qts_award_year}", year: year_for_answer.to_s(:long))
    end

    private

    def not_teaching_maths_or_physics?
      teaching_maths_or_physics == false
    end

    def ineligible_current_school?
      current_school.present? && !current_school.eligible_for_maths_and_physics?
    end

    # Returns true only if we can determine that they do not have a qualification
    # in maths or physics. If they are not sure about their ITT specialism, they
    # may still qualify, otherwise we require that they have an ITT in maths or
    # physics or a degree in either maths or physics.
    def no_maths_or_physics_qualification?
      !itt_specialism_not_sure? &&
        !initial_teacher_training_specialised_in_maths_or_physics? &&
        (has_uk_maths_or_physics_degree == "no")
    end

    def ineligible_qts_award_year?
      awarded_qualified_status_before_cut_off_date?
    end

    def no_entire_term_contract?
      employed_as_supply_teacher? && has_entire_term_contract == false
    end

    def not_employed_directly?
      employed_as_supply_teacher? && employed_directly == false
    end
  end
end
