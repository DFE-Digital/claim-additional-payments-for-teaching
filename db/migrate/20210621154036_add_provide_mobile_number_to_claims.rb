class AddProvideMobileNumberToClaims < ActiveRecord::Migration[6.0]
  def change
    add_column :claims, :provide_mobile_number, :boolean
  end
end
