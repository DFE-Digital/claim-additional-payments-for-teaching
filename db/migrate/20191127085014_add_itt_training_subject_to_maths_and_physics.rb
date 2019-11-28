class AddIttTrainingSubjectToMathsAndPhysics < ActiveRecord::Migration[6.0]
  def change
    add_column :maths_and_physics_eligibilities, :initial_teacher_training_subject, :integer
  end
end
