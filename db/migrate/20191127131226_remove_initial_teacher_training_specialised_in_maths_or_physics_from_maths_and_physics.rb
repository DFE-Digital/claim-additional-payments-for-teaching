class RemoveInitialTeacherTrainingSpecialisedInMathsOrPhysicsFromMathsAndPhysics < ActiveRecord::Migration[6.0]
  def change
    remove_column :maths_and_physics_eligibilities, :initial_teacher_training_specialised_in_maths_or_physics
  end
end
