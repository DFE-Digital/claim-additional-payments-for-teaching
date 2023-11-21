class DefaultLoggedInWithTidToNil < ActiveRecord::Migration[7.0]
  def change
    change_column_default :claims, :logged_in_with_tid, nil
  end
end
