class AddDeletedAtToReminders < ActiveRecord::Migration[7.2]
  def change
    add_column :reminders, :deleted_at, :datetime
  end
end
