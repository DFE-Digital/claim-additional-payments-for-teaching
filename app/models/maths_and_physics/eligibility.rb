module MathsAndPhysics
  class Eligibility < ApplicationRecord
    EDITABLE_ATTRIBUTES = [
      :teaching_maths_or_physics,
      :current_school_id,
      :initial_teacher_training_specialised_in_maths_or_physics,
      :has_uk_maths_or_physics_degree,
      :qts_award_year,
    ].freeze
    ATTRIBUTE_DEPENDENCIES = {
      "initial_teacher_training_specialised_in_maths_or_physics" => ["has_uk_maths_or_physics_degree"],
    }.freeze
    self.table_name = "maths_and_physics_eligibilities"

    enum has_uk_maths_or_physics_degree: {
      yes: 0,
      no: 1,
      has_non_uk: 2,
    }

    enum qts_award_year: {
      "before_september_2014": 0,
      "on_or_after_september_2014": 1,
    }, _prefix: :awarded_qualified_status

    belongs_to :current_school, optional: true, class_name: "School"

    validates :teaching_maths_or_physics, on: [:"teaching-maths-or-physics", :submit], inclusion: {in: [true, false], message: "Select either Yes or No"}
    validates :current_school, on: [:"current-school", :submit], presence: {message: "Select a school from the list"}
    validates :initial_teacher_training_specialised_in_maths_or_physics, on: [:"initial-teacher-training-specialised-in-maths-or-physics", :submit], inclusion: {in: [true, false], message: "Select either Yes or No"}
    validates :has_uk_maths_or_physics_degree, on: [:"has-uk-maths-or-physics-degree", :submit], presence: {message: "Select whether you have a UK maths or physics degree."}, unless: :initial_teacher_training_specialised_in_maths_or_physics?
    validates :qts_award_year, on: [:"qts-year", :submit], presence: {message: "Select the academic year you were awarded qualified teacher status"}

    delegate :name, to: :current_school, prefix: true, allow_nil: true

    def ineligible?
      not_teaching_maths_or_physics? ||
        ineligible_current_school? ||
        no_maths_or_physics_qualification? ||
        ineligible_qts_award_year?
    end

    def ineligibility_reason
      [
        :not_teaching_maths_or_physics,
        :ineligible_current_school,
        :no_maths_or_physics_qualification,
        :ineligible_qts_award_year,
      ].find { |eligibility_check| send("#{eligibility_check}?") }
    end

    def reset_dependent_answers
      ATTRIBUTE_DEPENDENCIES.each do |attribute_name, dependent_attribute_names|
        dependent_attribute_names.each do |dependent_attribute_name|
          write_attribute(dependent_attribute_name, nil) if changed.include?(attribute_name)
        end
      end
    end

    private

    def not_teaching_maths_or_physics?
      teaching_maths_or_physics == false
    end

    def ineligible_current_school?
      current_school.present? && !current_school.eligible_for_maths_and_physics?
    end

    def no_maths_or_physics_qualification?
      initial_teacher_training_specialised_in_maths_or_physics == false && has_uk_maths_or_physics_degree == "no"
    end

    def ineligible_qts_award_year?
      awarded_qualified_status_before_september_2014?
    end
  end
end
