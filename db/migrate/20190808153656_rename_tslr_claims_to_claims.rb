class RenameTslrClaimsToClaims < ActiveRecord::Migration[5.2]
  def change
    rename_table :tslr_claims, :claims
  end
end
