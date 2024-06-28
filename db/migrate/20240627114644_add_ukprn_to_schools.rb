class AddUkprnToSchools < ActiveRecord::Migration[7.0]
  def change
    add_column :schools, :ukprn, :text, null: true

    add_index :schools, :ukprn
  end
end
