class AddPolicyToClaim < ActiveRecord::Migration[8.0]
  def up
    add_column :claims, :policy, :text, null: true
    add_index :claims, :policy

    Claim.reset_column_information

    Claim
      .update_all("policy= regexp_replace(eligibility_type, '::\\w+$', '')")
  end

  def down
    remove_column :claims, :policy, :text, null: true
  end
end
