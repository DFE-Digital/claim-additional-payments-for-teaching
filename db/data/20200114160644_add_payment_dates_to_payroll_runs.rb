class AddPaymentDatesToPayrollRuns < ActiveRecord::Migration[6.0]
  def up
    PayrollRun.where.not(confirmation_report_uploaded_by: nil).each do |payroll_run|
      payroll_run.scheduled_payment_date = payroll_run.updated_at.to_date.next_occurring(:friday)
      payroll_run.save!
    end
  end

  def down
    PayrollRun.all.each do |payroll_run|
      payroll_run.scheduled_payment_date = nil
      payroll_run.save
    end
  end
end
