class AddEmployedAsSupplyTeacherToMathsAndPhysicsEligibilities < ActiveRecord::Migration[6.0]
  def change
    add_column :maths_and_physics_eligibilities, :employed_as_supply_teacher, :boolean
  end
end
