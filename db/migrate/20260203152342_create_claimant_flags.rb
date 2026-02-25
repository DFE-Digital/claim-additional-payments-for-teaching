class CreateClaimantFlags < ActiveRecord::Migration[8.1]
  def change
    create_table :claimant_flags, id: :uuid do |t|
      t.string :identification_attribute, null: false
      t.string :identification_value, null: false
      t.string :reason, null: false
      t.string :suggested_action
      t.string :policy, null: false
      t.belongs_to(
        :previous_claim,
        null: true,
        foreign_key: {
          to_table: :claims
        },
        type: :uuid
      )

      t.timestamps
    end
  end
end
