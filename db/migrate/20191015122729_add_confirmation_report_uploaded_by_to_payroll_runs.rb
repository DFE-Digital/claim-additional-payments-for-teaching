class AddConfirmationReportUploadedByToPayrollRuns < ActiveRecord::Migration[5.2]
  def change
    add_column :payroll_runs, :confirmation_report_uploaded_by, :string
  end
end
