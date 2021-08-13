class AddEmailVerifiedToClaim < ActiveRecord::Migration[6.0]
  def change
    add_column :claims, :email_verified, :boolean, default: false, after: :email_address
  end
end
