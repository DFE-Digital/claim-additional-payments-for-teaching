class AddEstablishmentNumberToSchools < ActiveRecord::Migration[5.2]
  def change
    add_column :schools, :establishment_number, :integer
  end
end
