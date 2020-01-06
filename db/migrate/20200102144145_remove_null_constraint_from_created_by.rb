class RemoveNullConstraintFromCreatedBy < ActiveRecord::Migration[6.0]
  def change
    change_column :payroll_runs, :created_by, :string, null: true
  end
end
