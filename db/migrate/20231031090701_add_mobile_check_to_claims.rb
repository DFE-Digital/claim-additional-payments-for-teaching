class AddMobileCheckToClaims < ActiveRecord::Migration[7.0]
  def change
    add_column :claims, :mobile_check, :string, default: nil
  end
end
