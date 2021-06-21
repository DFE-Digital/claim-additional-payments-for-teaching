class CreateReminders < ActiveRecord::Migration[6.0]
  def change
    create_table :reminders, id: :uuid do |t|
      t.string :full_name
      t.string :email_address

      t.timestamps
    end
  end
end
