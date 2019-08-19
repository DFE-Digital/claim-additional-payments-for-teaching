class AddVerifyResponseToClaim < ActiveRecord::Migration[5.2]
  def change
    add_column :claims, :verify_response, :json
  end
end
