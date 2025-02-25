class MakeApprovedNonNull < ActiveRecord::Migration[8.0]
  def change
    change_column_null :decisions, :approved, false
  end
end
