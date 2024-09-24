class AddJourneyToReminders < ActiveRecord::Migration[7.0]
  def up
    add_column :reminders, :journey_class, :string

    # Additional payments journey was not open when migration created, however
    # the FurtherEducationPayments journey was opened for the first time on
    # 2024/9/9 and so some reminders may also be set for the
    # FurtherEducationPayments journey
    Reminder.where("created_at < ?", Date.new(2024, 9, 9)).update_all(journey_class: Journeys::AdditionalPaymentsForTeaching.to_s)
    Reminder.not_yet_sent.where("created_at >= ?", Date.new(2024, 9, 9)).update_all(journey_class: Journeys::FurtherEducationPayments.to_s)

    change_column_null :reminders, :journey_class, false
    add_index :reminders, :journey_class
  end

  def down
    remove_column :reminders, :journey_class
  end
end
