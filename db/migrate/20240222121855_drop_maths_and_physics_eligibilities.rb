class DropMathsAndPhysicsEligibilities < ActiveRecord::Migration[7.0]
  def up
    drop_table :maths_and_physics_eligibilities, if_exists: true
  end
end
