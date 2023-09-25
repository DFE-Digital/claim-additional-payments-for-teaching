class AddDateIndexesToSchools < ActiveRecord::Migration[7.0]
  def change
    add_index :schools, :open_date
    add_index :schools, :close_date
  end
end
