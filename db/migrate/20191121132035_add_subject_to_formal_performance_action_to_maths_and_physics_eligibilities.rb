class AddSubjectToFormalPerformanceActionToMathsAndPhysicsEligibilities < ActiveRecord::Migration[6.0]
  def change
    add_column :maths_and_physics_eligibilities, :subject_to_formal_performance_action, :boolean
  end
end
