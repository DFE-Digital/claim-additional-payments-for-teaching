# Run me with `rails runner db/data/20200227163004_update_payroll_run_uploaded_by_id.rb`

PayrollRun.all.each do |payroll_run|
  user_id = payroll_run.read_attribute(:confirmation_report_uploaded_by)
  next unless user_id.present?
  user = DfeSignIn::User.find_or_create_by(dfe_sign_in_id: user_id)
  payroll_run.update_column(:confirmation_report_uploaded_by_id, user.id)
end
