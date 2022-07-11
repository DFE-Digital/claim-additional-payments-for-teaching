class AddPolicyOptionsProvidedToClaims < ActiveRecord::Migration[6.0]
  def change
    add_column :claims, :policy_options_provided, :jsonb, default: []
  end
end
