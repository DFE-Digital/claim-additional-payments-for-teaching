class AddStatutoryHighAgeToSchools < ActiveRecord::Migration[6.0]
  def change
    add_column :schools, :statutory_high_age, :integer
  end
end
