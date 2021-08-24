class AddAcademicYearToReminders < ActiveRecord::Migration[6.0]
  def change
    add_column :reminders, :itt_academic_year, :string, limit: 9
  end
end
