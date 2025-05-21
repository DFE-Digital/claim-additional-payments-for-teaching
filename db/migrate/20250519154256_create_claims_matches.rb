class CreateClaimsMatches < ActiveRecord::Migration[8.0]
  def change
    create_table :claims_matches, id: :uuid do |t|
      t.belongs_to(
        :source_claim,
        null: false,
        foreign_key: {to_table: :claims},
        type: :uuid
      )

      t.belongs_to(
        :matching_claim,
        null: false,
        foreign_key: {to_table: :claims},
        type: :uuid
      )

      t.text :matching_attributes, null: false, array: true, default: []

      t.timestamps
    end

    add_index(
      :claims_matches,
      [:source_claim_id, :matching_claim_id],
      unique: true,
      name: "index_claims_matches_on_source_and_matching_claim"
    )
  end
end
