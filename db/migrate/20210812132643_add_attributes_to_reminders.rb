class AddAttributesToReminders < ActiveRecord::Migration[6.0]
  def change
    add_column :reminders, :email_verified, :boolean, default: false
    add_column :reminders, :email_sent_at, :datetime
  end
end
