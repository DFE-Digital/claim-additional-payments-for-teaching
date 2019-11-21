class AddHasEntireTermContractToMathsAndPhysicsEligibilities < ActiveRecord::Migration[6.0]
  def change
    add_column :maths_and_physics_eligibilities, :has_entire_term_contract, :boolean
  end
end
