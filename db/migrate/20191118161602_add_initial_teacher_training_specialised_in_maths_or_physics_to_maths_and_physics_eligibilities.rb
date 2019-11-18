class AddInitialTeacherTrainingSpecialisedInMathsOrPhysicsToMathsAndPhysicsEligibilities < ActiveRecord::Migration[6.0]
  def change
    add_column :maths_and_physics_eligibilities, :initial_teacher_training_specialised_in_maths_or_physics, :boolean
  end
end
