class AddEmailAddressCheckToClaims < ActiveRecord::Migration[7.0]
  def change
    add_column :claims, :email_address_check, :boolean, default: nil
  end
end
