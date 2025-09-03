class AddPractitionerReminderFieldsToEarlyYearsPaymentsEligibility < ActiveRecord::Migration[8.0]
  def change
    add_column :early_years_payment_eligibilities, :practitioner_reminder_email_sent_count, :integer, default: 0, null: false
    add_column :early_years_payment_eligibilities, :practitioner_reminder_email_last_sent_at, :datetime

    add_index :early_years_payment_eligibilities, :practitioner_reminder_email_sent_count, name: "index_ey_eligibilities_on_pract_reminder_count"
    add_index :early_years_payment_eligibilities, :practitioner_reminder_email_last_sent_at, name: "index_ey_eligibilities_on_pract_reminder_last_sent"
  end
end
