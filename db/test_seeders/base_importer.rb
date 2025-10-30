require "csv"

if ENV["ENVIRONMENT_NAME"] == "development" ||
    ENV["ENVIRONMENT_NAME"] == "test" ||
    ENV["ENVIRONMENT_NAME"] == "local"
  require "faker"
  require "activerecord-copy"

  Faker::Config.random = Random.new(srand(1234))
  Faker::Config.locale = "en-GB"
  Faker::UniqueGenerator.clear
  Random.new(srand(1234))
end

class BaseImporter
  include Seeder

  def initialize(policies:, **kwargs)
    @policies = policies
    @test_type = kwargs[:test_type]
    @quantities = kwargs[:quantities]
    @records = []
    @logger = Logger.new($stdout)
    clear_data
  end

  private

  attr_reader :policies,
    :policy,
    :logger,
    :test_type,
    :quantities,
    :quantity

  def clear_data
    Note.delete_all
    Task.delete_all
    Amendment.delete_all
    Decision.delete_all
    SupportTicket.delete_all
    Claim.delete_all
    Policies::EarlyCareerPayments::Eligibility.delete_all
    StudentLoans::Eligibility.delete_all
    Payment.delete_all
    PayrollRun.delete_all
    Reminder.delete_all
  end

  def filename
    if policy == Policies::EarlyCareerPayments
      if ENV["ENVIRONMENT_NAME"] == "local"
        Rails.root.join("db", "test_seeders", "data", "dqt_testing", "ecp_test_seed_data_five_records.csv")
      elsif ENV["ENVIRONMENT_NAME"] == "development" || ENV["ENVIRONMENT_NAME"] == "test"
        Rails.root.join("db", "test_seeders", "data", "dqt_testing", "ecp_test_seed_data_254_records.csv")
      end
    elsif policy == Policies::StudentLoans
      if ENV["ENVIRONMENT_NAME"] == "local"
        Rails.root.join("db", "test_seeders", "data", "dqt_testing", "tslr_test_seed_data_24_records.csv")
      elsif ENV["ENVIRONMENT_NAME"] == "development" || ENV["ENVIRONMENT_NAME"] == "test"
        Rails.root.join("db", "test_seeders", "data", "dqt_testing", "tslr_test_seed_data_98_records.csv")
      end
    end
  end

  def read_test_csv
    logger.info "Reading csv data from #{filename}"
    CSV.foreach(filename, encoding: "iso-8859-1:utf-8", headers: true) do |row|
      @records << row
    end
  end

  def submit_claims
    claims = Claim.unsubmitted
    logger.info LINE
    logger.info "Submitting #{claims.size} unsumitted claims for Claim Verification"
    claims.map(&:submit!)
  end

  # only run for DqT CSV Seeded data
  # 99.9% of randomly generated data will never match (unless a fluke)
  def run_jobs
    return if test_type == :volume

    logger.info BOLD_LINE
    logger.info "Clearing down background jobs..."
    Rake::Task["jobs:clear"].invoke
    Claim.submitted.each do |claim|
      ClaimVerifierJob.perform_later(claim)
    end

    Rake::Task["jobs:workoff"].invoke
    logger.info BOLD_LINE
  end

  def admin_approver
    user = DfeSignIn::User.find { |u| u.role_codes.include?("teacher_payments_access") }
    if user.nil?
      logger.warn "#{WARN} - No Admin User found with 'teacher_payments_access' role"
      logger.warn "#{WARN} - Please sign-in as Department for Education Admin user ('teacher_payments_access')"
      exit 100
    end
    user
  end
end
