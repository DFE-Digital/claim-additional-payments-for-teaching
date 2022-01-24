require_relative "../../db/seeds/data_importer"

# NB This task is NOT to be run in PRODUCTION. It clears down the database.
# Its sole purpose is to seed large volumes of realistic test data for testing
# - DqT test data (ECP-1379)
# - Large volume data for Payroll move from Cantium to In-house (ECP-1380)
namespace :test_data_seeder do
  desc "bulk imports data from csv for DqT testing of ECP claims"
  task "dqt_data:ecp" => :environment do
    abort("Not to be run in 'PRODUCTION!") if ENV.fetch("ENVIRONMENT_NAME") == "production" && Rails.env.production?

    %w[db:drop db:create db:schema:load].each do |rake_task|
      Rake::Task[rake_task].invoke
    end
    logger = Logger.new($stdout)
    logger.info "Importing EarlyCareerPayments DqT seed data, this may take a couple minutes..."
    DataImporter.new(policy: EarlyCareerPayments).run
    logger.info "Seeding data import complete!"
  end
end
