class AddEmployedDirectlyToMathsAndPhysicsEligibilities < ActiveRecord::Migration[6.0]
  def change
    add_column :maths_and_physics_eligibilities, :employed_directly, :boolean
  end
end
