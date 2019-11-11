module MathsAndPhysics
  class Eligibility < ApplicationRecord
    EDITABLE_ATTRIBUTES = [
      :teaching_maths_or_physics,
    ].freeze
    self.table_name = "maths_and_physics_eligibilities"

    validates :teaching_maths_or_physics, on: [:"teaching-maths-or-physics", :submit], inclusion: {in: [true, false], message: "Select either Yes or No"}

    def ineligible?
      not_teaching_maths_or_physics?
    end

    def ineligibility_reason
      [
        :not_teaching_maths_or_physics,
      ].find { |eligibility_check| send("#{eligibility_check}?") }
    end

    def reset_dependent_answers
    end

    private

    def not_teaching_maths_or_physics?
      teaching_maths_or_physics == false
    end
  end
end
