class AddDownloadedByToPayrollRuns < ActiveRecord::Migration[6.0]
  def change
    add_reference :payroll_runs, :downloaded_by, type: :uuid, foreign_key: {to_table: :dfe_sign_in_users}
  end
end
