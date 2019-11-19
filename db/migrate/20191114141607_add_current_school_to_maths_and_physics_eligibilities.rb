class AddCurrentSchoolToMathsAndPhysicsEligibilities < ActiveRecord::Migration[6.0]
  def change
    add_reference :maths_and_physics_eligibilities, :current_school, type: :uuid, foreign_key: {to_table: :schools}
  end
end
