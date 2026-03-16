class RmExtraOlIndex < ActiveRecord::Migration[8.1]
  def up
    execute <<-SQL
      DROP INDEX IF EXISTS sessions_one_login_existing_index
    SQL
  end

  def down
    execute <<-SQL
      CREATE INDEX sessions_one_login_existing_index ON journeys_sessions ((answers->>'onelogin_uid'), (answers #>> '{academic_year, start_year}'), (answers #>> '{academic_year, end_year}'))
    SQL
  end
end
