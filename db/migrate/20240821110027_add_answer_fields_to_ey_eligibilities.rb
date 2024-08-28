class AddAnswerFieldsToEyEligibilities < ActiveRecord::Migration[7.0]
  def change
    add_column :early_years_payment_eligibilities, :nursery_urn, :string
    add_column :early_years_payment_eligibilities, :start_date, :date
    add_column :early_years_payment_eligibilities, :child_facing_confirmation_given, :boolean
    add_column :early_years_payment_eligibilities, :first_job_within_6_months, :boolean
  end
end
