class AddOpenDateToSchools < ActiveRecord::Migration[6.0]
  def change
    add_column :schools, :open_date, :date
  end
end
