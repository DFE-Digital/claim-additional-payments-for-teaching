class AddOlClaimReturnCodes < ActiveRecord::Migration[8.0]
  def change
    add_column :claims, :onelogin_idv_return_codes, :text, array: true
  end
end
