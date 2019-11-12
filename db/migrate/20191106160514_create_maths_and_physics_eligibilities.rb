class CreateMathsAndPhysicsEligibilities < ActiveRecord::Migration[5.2]
  def change
    create_table :maths_and_physics_eligibilities, id: :uuid do |t|
      t.boolean :teaching_maths_or_physics
      t.timestamps
    end
  end
end
