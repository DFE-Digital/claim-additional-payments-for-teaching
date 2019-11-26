class AddDownloadedAtAndByToPayrollRuns < ActiveRecord::Migration[6.0]
  def change
    add_column :payroll_runs, :downloaded_at, :datetime
    add_column :payroll_runs, :downloaded_by, :string
  end
end
