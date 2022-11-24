class AddLuppAwards < ActiveRecord::Migration[6.1]
  def change
    create_table :levelling_up_premium_payments_awards do |t|
      t.string :academic_year, limit: 9, null: false
      t.integer :school_urn, null: false
      t.decimal :award_amount, precision: 7, scale: 2
      t.timestamps
    end

    add_index :levelling_up_premium_payments_awards, :academic_year, name: "lupp_award_by_year"
    add_index :levelling_up_premium_payments_awards, :school_urn, name: "lupp_award_by_urn"
    add_index :levelling_up_premium_payments_awards, :award_amount, name: "lupp_award_by_amount"
    add_index :levelling_up_premium_payments_awards, [:academic_year, :school_urn], name: "lupp_award_by_year_and_urn"
  end
end
