# This supports testing of the payroll run functionality. It probably shouldn't ever be run in production.
# Specify a PayrollRun ID - defaults to the last PayrollRun record
desc "Delete payroll run"
task :delete_payroll_run, [:payroll_run_id] => :environment do |t, args|
  args.with_defaults(payroll_run_id: PayrollRun.last.id)
  logger = Logger.new($stdout)
  logger.info "Deleting payroll run with ID #{args.payroll_run_id}"

  PayrollRun.find(args.payroll_run_id).destroy!
end
