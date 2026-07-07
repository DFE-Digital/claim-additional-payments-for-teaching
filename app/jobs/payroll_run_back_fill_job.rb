class PayrollRunBackFillJob < ApplicationJob
  def perform
    payroll_runs = PayrollRun
      .includes(:payments, :payment_confirmations)
      .order(created_at: :desc)

    payroll_runs.each do |payroll_run|
      payroll_run.update!(
        claims_count: payroll_run.number_of_claims_for_policy(:all, filter: :claims),
        topups_count: payroll_run.number_of_claims_for_policy(:all, filter: :topups),
        total_confirmed_payments: payroll_run.payments.where.not(confirmation: nil).count,
        payments_count: payroll_run.payments.count,
        payment_confirmation_uploaded: payroll_run.payment_confirmations.any?
      )
    end
  end
end
