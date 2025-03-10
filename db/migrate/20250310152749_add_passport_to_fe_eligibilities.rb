class AddPassportToFeEligibilities < ActiveRecord::Migration[8.0]
  def change
    add_column :further_education_payments_eligibilities, :valid_passport, :boolean, null: true
    add_column :further_education_payments_eligibilities, :passport_number, :text, null: true
  end
end
