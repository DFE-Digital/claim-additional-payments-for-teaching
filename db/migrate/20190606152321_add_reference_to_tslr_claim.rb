class AddReferenceToTslrClaim < ActiveRecord::Migration[5.2]
  def change
    add_column :tslr_claims, :reference, :string, limit: 8
    add_index :tslr_claims, :reference, unique: true
  end
end
