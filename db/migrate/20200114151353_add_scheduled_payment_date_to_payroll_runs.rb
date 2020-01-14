class AddScheduledPaymentDateToPayrollRuns < ActiveRecord::Migration[6.0]
  def change
    add_column :payroll_runs, :scheduled_payment_date, :date
  end
end
