class EyProvidersUnique < ActiveRecord::Migration[7.0]
  def change
    remove_index :eligible_ey_providers, [:urn]
    add_index :eligible_ey_providers, [:urn], unique: true
  end
end
