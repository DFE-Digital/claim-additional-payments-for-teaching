class CreatePoliciesDataRetentionRecoveries < ActiveRecord::Migration[8.1]
  def change
    create_table :policies_data_retention_recoveries, id: :uuid do |t|
      t.belongs_to :claim, null: false, foreign_key: true, type: :uuid
      t.datetime :destroy_at, null: false
      t.jsonb :payload

      t.timestamps
    end
  end
end
