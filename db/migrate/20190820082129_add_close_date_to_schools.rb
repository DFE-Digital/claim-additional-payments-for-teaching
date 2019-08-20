class AddCloseDateToSchools < ActiveRecord::Migration[5.2]
  def change
    add_column :schools, :close_date, :date
  end
end
