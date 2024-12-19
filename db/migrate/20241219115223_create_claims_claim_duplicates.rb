class CreateClaimsClaimDuplicates < ActiveRecord::Migration[8.0]
  def change
    create_table :claims_claim_duplicates, id: :uuid do |t|
      t.belongs_to(
        :original_claim,
        null: false,
        foreign_key: {
          to_table: :claims
        },
        type: :uuid
      )

      t.belongs_to(
        :duplicate_claim,
        null: false,
        foreign_key: {
          to_table: :claims
        },
        type: :uuid
      )

      t.jsonb :matching_attributes, default: []

      t.timestamps
    end

    add_index(
      :claims_claim_duplicates,
      [:original_claim_id, :duplicate_claim_id],
      unique: true
    )
  end
end
