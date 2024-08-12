class AddTrnToFeEligibilities < ActiveRecord::Migration[7.0]
  def change
    add_column :further_education_payments_eligibilities, :teacher_reference_number, :text
  end
end
