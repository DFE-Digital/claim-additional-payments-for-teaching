class AddStatusToPayrollRuns < ActiveRecord::Migration[7.0]
  def change
    add_column :payroll_runs, :status, :string, default: "pending", null: false

    PayrollRun.update_all(status: "complete")
  end
end
