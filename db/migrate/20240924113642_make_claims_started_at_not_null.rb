class MakeClaimsStartedAtNotNull < ActiveRecord::Migration[7.0]
  def change
    change_column_null :claims, :started_at, false
  end
end
