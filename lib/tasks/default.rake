task(:default).clear_prerequisites.enhance(%i[shellcheck standard prettier brakeman:run spec]) if Rails.env.test? || Rails.env.development?

desc "Runs setup if database does not exist, or runs migrations if it does"
db_namespace = namespace(:db) {
  task setup_or_migrate: :load_config do
    ActiveRecord::Base.configurations.configs_for(env_name: Rails.env).each do |db_config|
      ActiveRecord::Base.establish_connection(db_config.configuration_hash)

      connection = ActiveRecord::Base.connection
      schema_migration = ActiveRecord::SchemaMigration.new(connection.pool)

      if schema_migration.table_exists?
        db_namespace["migrate"].invoke
      else
        db_namespace["setup"].invoke
      end
    rescue ActiveRecord::NoDatabaseError
      db_namespace["setup"].invoke
    end
  end
}
