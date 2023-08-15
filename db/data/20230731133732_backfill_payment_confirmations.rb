# Run me with `rails runner db/data/20230731133732_backfill_payment_confirmations.rb`

PayrollRun.where.not(confirmation_report_uploaded_by: nil).each do |payroll_run|
  next if payroll_run.payment_confirmations.any?

  puts "Backfilling payroll run #{payroll_run.id}..."
  batches = payroll_run.payments.includes(:claims).in_batches(of: PayrollRun::MAX_BATCH_SIZE)
  batches.each.with_index(1) do |payment_batch, index|
    confirmation = PaymentConfirmation.create!(
      payroll_run: payroll_run,
      created_by: payroll_run.confirmation_report_uploaded_by
    )
    payment_batch.update_all(confirmation_id: confirmation.reload.id, scheduled_payment_date: payroll_run.scheduled_payment_date)
    puts "   Created confirmation #{index} of #{batches.count} for #{payment_batch.count} payments scheduled on #{payroll_run.scheduled_payment_date}"
  end
  puts
end
