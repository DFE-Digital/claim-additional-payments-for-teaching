class CreateClaimsMatch < ActiveRecord::Migration[8.1]
  def change
    create_table :claims_matches, id: :uuid do |t|
      t.belongs_to(
        :left_claim,
        null: false,
        foreign_key: {
          to_table: :claims
        },
        type: :uuid
      )

      t.belongs_to(
        :right_claim,
        null: false,
        foreign_key: {
          to_table: :claims
        },
        type: :uuid
      )

      t.jsonb :matching_attributes, default: [], null: false

      t.timestamps
    end

    add_index(
      :claims_matches,
      [:left_claim_id, :right_claim_id],
      unique: true,
      name: "index_claims_matches_on_left_and_right_claim_id"
    )
  end
end
