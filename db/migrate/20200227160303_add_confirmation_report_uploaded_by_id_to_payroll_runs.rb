class AddConfirmationReportUploadedByIdToPayrollRuns < ActiveRecord::Migration[6.0]
  def change
    add_reference :payroll_runs, :confirmation_report_uploaded_by, type: :uuid, foreign_key: {to_table: :dfe_sign_in_users}
  end
end
