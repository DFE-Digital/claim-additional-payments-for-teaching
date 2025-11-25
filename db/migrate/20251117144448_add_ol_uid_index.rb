class AddOlUidIndex < ActiveRecord::Migration[8.1]
  def change
    execute <<-SQL
      CREATE INDEX sessions_one_login_uid_index ON journeys_sessions ((answers->>'onelogin_uid'))
    SQL
  end
end
