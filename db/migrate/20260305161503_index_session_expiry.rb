class IndexSessionExpiry < ActiveRecord::Migration[8.1]
  def change
    add_index :journeys_sessions, :expired
  end
end
