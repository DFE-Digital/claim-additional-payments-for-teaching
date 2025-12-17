require_relative "../../db/test_seeders/data_importer"

# NB This task is NOT to be run in PRODUCTION. It clears down the database.
# Its sole purpose is to seed large volumes of realistic test data for testing
# - DqT test data (ECP-1379/1381)
# - Large volume data for Payroll move from Cantium to In-house (ECP-1380)
namespace :test_data_seeder do
  desc "bulk imports data from csv for DqT testing of ECP claims"
  task "dqt_data:ecp" => :environment do
    abort("Not to be run in 'PRODUCTION!") if ENV.fetch("ENVIRONMENT_NAME") == "production" && Rails.env.production?

    logger = Logger.new($stdout)
    logger.info "Importing EarlyCareerPayments DqT seed data, this may take a couple minutes..."
    DataImporter.new(policies: [Policies::EarlyCareerPayments], test_type: :dqt_csv, quantities: {early_career_payments: nil}).run
    logger.info "Seeding data import complete!"
  end

  desc "bulk imports data from csv for DqT testing of TSLR claims"
  task "dqt_data:tslr" => :environment do
    abort("Not to be run in 'PRODUCTION!") if ENV.fetch("ENVIRONMENT_NAME") == "production" && Rails.env.production?

    logger = Logger.new($stdout)
    logger.info "Importing StudentLoans DqT seed data, this may take a couple minutes..."
    DataImporter.new(policies: [Policies::StudentLoans], test_type: :dqt_csv, quantities: {student_loans: nil}).run
    logger.info "Seeding data import complete!"
  end

  desc "bulk imports ECP & TSLR data to postgresql for volume testing"
  task :bulk, [:early_career_payments, :student_loans] => :environment do |t, args|
    abort("Not to be run in 'PRODUCTION!") if ENV.fetch("ENVIRONMENT_NAME") == "production" && Rails.env.production?

    args.with_defaults(early_career_payments: 2000, student_loans: 0)
    logger = Logger.new($stdout)
    policies = []
    quantities = {}
    early_career_payments_volume = args[:early_career_payments]
    student_loans_volume = args[:student_loans]
    if early_career_payments_volume.to_i > 0
      policies << Policies::EarlyCareerPayments
      quantities[:early_career_payments] = early_career_payments_volume
    end
    if student_loans_volume.to_i > 0
      policies << StudentLoans
      quantities[:student_loans] = student_loans_volume
    end

    logger.info "EarlyCareerPayments volume: #{early_career_payments_volume}"
    logger.info "StudentLoans volume: #{student_loans_volume}"
    logger.info "Generating & importing seed data, this may take a couple minutes..."
    DataImporter.new(policies: policies, test_type: :volume, quantities: quantities).run
    logger.info "Seeding data import complete!"
  end

  desc "generate STRI awards CSV from personas"
  task "generate_stri_awards" => :environment do
    puts Policies::TargetedRetentionIncentivePayments::Test::StriAwardsGenerator.to_csv
  end
end
