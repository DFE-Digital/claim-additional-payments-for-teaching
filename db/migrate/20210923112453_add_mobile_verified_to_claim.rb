class AddMobileVerifiedToClaim < ActiveRecord::Migration[6.0]
  def change
    add_column :claims, :mobile_verified, :boolean, default: false
  end
end
