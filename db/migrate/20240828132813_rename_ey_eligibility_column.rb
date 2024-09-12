class RenameEyEligibilityColumn < ActiveRecord::Migration[7.0]
  def change
    rename_column :early_years_payment_eligibilities, :first_job_within_6_months, :returning_within_6_months
  end
end
