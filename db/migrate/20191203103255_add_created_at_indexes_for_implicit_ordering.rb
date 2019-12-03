class AddCreatedAtIndexesForImplicitOrdering < ActiveRecord::Migration[6.0]
  def change
    add_index :checks, :created_at
    add_index :claims, :created_at
    add_index :maths_and_physics_eligibilities, :created_at
    add_index :payments, :created_at
    add_index :payroll_runs, :created_at
    add_index :policy_configurations, :created_at
    add_index :schools, :created_at
    add_index :student_loans_eligibilities, :created_at
  end
end
