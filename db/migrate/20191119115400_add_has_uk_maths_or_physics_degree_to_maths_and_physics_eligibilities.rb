class AddHasUkMathsOrPhysicsDegreeToMathsAndPhysicsEligibilities < ActiveRecord::Migration[6.0]
  def change
    add_column :maths_and_physics_eligibilities, :has_uk_maths_or_physics_degree, :integer
  end
end
