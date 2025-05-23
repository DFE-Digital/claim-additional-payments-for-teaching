class NotNullClaimsPolicy < ActiveRecord::Migration[8.0]
  def change
    change_column_null :claims, :policy, false
  end
end
