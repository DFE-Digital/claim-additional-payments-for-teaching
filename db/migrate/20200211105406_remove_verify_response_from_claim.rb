class RemoveVerifyResponseFromClaim < ActiveRecord::Migration[6.0]
  def change
    remove_column :claims, :verify_response, :json
  end
end
