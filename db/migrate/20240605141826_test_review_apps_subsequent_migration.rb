class TestReviewAppsSubsequentMigration < ActiveRecord::Migration[7.0]
  def change
    add_column :claims, :test_column, :text, default:"test"
  end
end
