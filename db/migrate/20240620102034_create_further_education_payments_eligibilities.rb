class CreateFurtherEducationPaymentsEligibilities < ActiveRecord::Migration[7.0]
  def change
    create_table :further_education_payments_eligibilities, id: :uuid do |t|
      t.timestamps
    end
  end
end
