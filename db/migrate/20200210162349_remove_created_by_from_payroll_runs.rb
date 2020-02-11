class RemoveCreatedByFromPayrollRuns < ActiveRecord::Migration[6.0]
  def change
    remove_column :payroll_runs, :created_by
  end
end
