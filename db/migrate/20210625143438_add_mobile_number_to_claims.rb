class AddMobileNumberToClaims < ActiveRecord::Migration[6.0]
  def change
    add_column :claims, :mobile_number, :string
  end
end
