class RedoLupToTriTables < ActiveRecord::Migration[8.0]
  def up
    drop_table :targeted_retention_incentive_payments_awards

    create_table :targeted_retention_incentive_payments_awards, id: :bigint do |t|
      t.string :academic_year, limit: 9, null: false
      t.integer :school_urn, null: false
      t.decimal :award_amount, precision: 7, scale: 2
      t.references :file_upload, type: :uuid, foreign_key: true, null: true

      t.timestamps
    end

    add_index :targeted_retention_incentive_payments_awards, [:academic_year, :school_urn, :file_upload_id]
    add_index :targeted_retention_incentive_payments_awards, :academic_year
    add_index :targeted_retention_incentive_payments_awards, :award_amount
    add_index :targeted_retention_incentive_payments_awards, :school_urn
  end
end
