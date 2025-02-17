class CreateTargetedRetentionIncentivePaymentsAwards < ActiveRecord::Migration[8.0]
  def change
    create_table :targeted_retention_incentive_payments_awards, id: :uuid, if_not_exists: true do |t|
      t.string :academic_year, limit: 9, null: false
      t.integer :school_urn, null: false
      t.decimal :award_amount, precision: 7, scale: 2
      t.references :file_upload, type: :uuid, foreign_key: true, null: true

      t.timestamps
    end

    add_index :targeted_retention_incentive_payments_awards, [:academic_year, :school_urn, :file_upload_id], if_not_exists: true
    add_index :targeted_retention_incentive_payments_awards, :academic_year, if_not_exists: true
    add_index :targeted_retention_incentive_payments_awards, :award_amount, if_not_exists: true
    add_index :targeted_retention_incentive_payments_awards, :school_urn, if_not_exists: true
  end
end
