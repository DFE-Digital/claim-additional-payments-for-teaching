class AddProviderSixMonthEmploymentReminderSentAtToEligibility < ActiveRecord::Migration[8.0]
  def change
    add_column(
      :early_years_payment_eligibilities,
      :provider_six_month_employment_reminder_sent_at,
      :datetime,
      null: true
    )
  end
end
