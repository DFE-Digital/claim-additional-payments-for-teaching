class RedoIndexSessionsOlIndex < ActiveRecord::Migration[8.1]
  def up
    execute <<-SQL
      DROP INDEX sessions_one_login_uid_index;
      CREATE INDEX sessions_one_login_uid_index ON journeys_sessions ((answers#>>'{onelogin_uid}'));
    SQL
  end

  def down
    execute <<-SQL
      DROP INDEX sessions_one_login_uid_index;
      CREATE INDEX sessions_one_login_uid_index ON journeys_sessions ((answers->>'onelogin_uid'));
    SQL
  end
end
