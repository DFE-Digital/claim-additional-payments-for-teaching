class AddGenderDigitToTps < ActiveRecord::Migration[6.1]
  def change
    add_column :teachers_pensions_service, :gender_digit, :integer
  end
end
