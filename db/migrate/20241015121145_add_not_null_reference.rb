class AddNotNullReference < ActiveRecord::Migration[7.0]
  def change
    change_column_null :claims, :reference, false
  end
end
