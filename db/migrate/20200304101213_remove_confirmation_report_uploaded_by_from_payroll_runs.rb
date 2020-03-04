class RemoveConfirmationReportUploadedByFromPayrollRuns < ActiveRecord::Migration[6.0]
  def change
    remove_column :payroll_runs, :confirmation_report_uploaded_by, :string
  end
end
