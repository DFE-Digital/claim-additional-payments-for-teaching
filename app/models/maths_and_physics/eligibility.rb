module MathsAndPhysics
  class Eligibility < ApplicationRecord
    EDITABLE_ATTRIBUTES = [
      :teaching_maths_or_physics,
      :current_school_id,
      :initial_teacher_training_specialised_in_maths_or_physics,
    ].freeze
    self.table_name = "maths_and_physics_eligibilities"

    belongs_to :current_school, optional: true, class_name: "School"

    validates :teaching_maths_or_physics, on: [:"teaching-maths-or-physics", :submit], inclusion: {in: [true, false], message: "Select either Yes or No"}
    validates :current_school, on: [:"current-school", :submit], presence: {message: "Select a school from the list"}
    validates :initial_teacher_training_specialised_in_maths_or_physics, on: [:"initial-teacher-training-specialised-in-maths-or-physics", :submit], inclusion: {in: [true, false], message: "Select either Yes or No"}

    delegate :name, to: :current_school, prefix: true, allow_nil: true

    def ineligible?
      not_teaching_maths_or_physics? || ineligible_current_school?
    end

    def ineligibility_reason
      [
        :not_teaching_maths_or_physics,
        :ineligible_current_school,
      ].find { |eligibility_check| send("#{eligibility_check}?") }
    end

    def reset_dependent_answers
    end

    private

    def not_teaching_maths_or_physics?
      teaching_maths_or_physics == false
    end

    def ineligible_current_school?
      current_school.present? && !current_school.eligible_for_maths_and_physics?
    end
  end
end
