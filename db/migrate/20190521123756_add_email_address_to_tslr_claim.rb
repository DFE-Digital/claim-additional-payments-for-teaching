class AddEmailAddressToTslrClaim < ActiveRecord::Migration[5.2]
  def change
    add_column :tslr_claims, :email_address, :string, limit: 256
  end
end
