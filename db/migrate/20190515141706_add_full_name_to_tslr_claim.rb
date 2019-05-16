class AddFullNameToTslrClaim < ActiveRecord::Migration[5.2]
  def change
    add_column :tslr_claims, :full_name, :string, limit: 200
  end
end
