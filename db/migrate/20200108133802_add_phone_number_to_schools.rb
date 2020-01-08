class AddPhoneNumberToSchools < ActiveRecord::Migration[6.0]
  def change
    add_column :schools, :phone_number, :string, limit: 20
  end
end
