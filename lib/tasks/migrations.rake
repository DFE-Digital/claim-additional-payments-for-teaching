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

  namespace :migrate do
    desc "Run db:migrate but ignore ActiveRecord::ConcurrentMigrationError errors when multiple worker and web instances are starting concurrently"
    task ignore_concurrent_migration_exceptions: :environment do
      Rake::Task["db:migrate"].invoke
    rescue ActiveRecord::ConcurrentMigrationError
      # Do nothing
    end
  end
}
