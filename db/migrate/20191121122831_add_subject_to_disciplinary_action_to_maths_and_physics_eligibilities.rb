class AddSubjectToDisciplinaryActionToMathsAndPhysicsEligibilities < ActiveRecord::Migration[6.0]
  def change
    add_column :maths_and_physics_eligibilities, :subject_to_disciplinary_action, :boolean
  end
end
