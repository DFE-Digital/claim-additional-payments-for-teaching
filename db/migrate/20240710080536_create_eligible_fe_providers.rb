class CreateEligibleFeProviders < ActiveRecord::Migration[7.0]
  def change
    create_table :eligible_fe_providers, id: :uuid do |t|
      t.integer :ukprn, null: false
      t.text :academic_year, limit: 9, null: false
      t.decimal :max_award_amount, precision: 7, scale: 2
      t.decimal :lower_award_amount, precision: 7, scale: 2

      t.timestamps
    end

    add_index :eligible_fe_providers, [:academic_year, :ukprn]
  end
end
