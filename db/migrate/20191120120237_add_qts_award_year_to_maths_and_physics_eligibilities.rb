class AddQtsAwardYearToMathsAndPhysicsEligibilities < ActiveRecord::Migration[6.0]
  def change
    add_column :maths_and_physics_eligibilities, :qts_award_year, :integer
  end
end
