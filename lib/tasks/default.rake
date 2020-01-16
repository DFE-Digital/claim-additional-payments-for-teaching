task(:default).clear_prerequisites.enhance(%i[shellcheck standard prettier brakeman:run spec]) if Rails.env.test? || Rails.env.development?

# Override the db:setup task to make sure entries for existing data migration
# are seeded in the data_migrations table when setting up for the first time.
Rake::Task["db:setup"].clear
namespace :db do
  task setup: ["db:create", "db:schema:load:with_data", "db:seed"]
end
