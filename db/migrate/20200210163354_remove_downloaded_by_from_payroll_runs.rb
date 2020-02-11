class RemoveDownloadedByFromPayrollRuns < ActiveRecord::Migration[6.0]
  def change
    remove_column :payroll_runs, :downloaded_by
  end
end
