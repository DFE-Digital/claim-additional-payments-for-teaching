class AddCalculatedColumnsToPayrollRun < ActiveRecord::Migration[8.1]
  def change
    add_column :payroll_runs, :claims_count, :integer
    add_column :payroll_runs, :topups_count, :integer
    add_column :payroll_runs, :total_confirmed_payments, :integer
    add_column :payroll_runs, :payments_count, :integer
    add_column :payroll_runs, :payment_confirmation_uploaded, :boolean, default: false
  end
end
