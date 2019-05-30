class AddSubmittedAtToTslrClaims < ActiveRecord::Migration[5.2]
  def change
    add_column :tslr_claims, :submitted_at, :datetime
    add_index :tslr_claims, :submitted_at
  end
end
