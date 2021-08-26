class AddIttSubjectToReminders < ActiveRecord::Migration[6.0]
  def change
    add_column :reminders, :itt_subject, :string
  end
end
