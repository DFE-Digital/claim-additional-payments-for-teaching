require "csv"
require "benchmark"

if ENV["ENVIRONMENT_NAME"] == "development" ||
    ENV["ENVIRONMENT_NAME"] == "test" ||
    ENV["ENVIRONMENT_NAME"] == "local"
  require "faker"

  Faker::Config.random = Random.new(srand(1234))
  Faker::Config.locale = "en-GB"
  Faker::UniqueGenerator.clear
  Random.new(srand(1234))
end

class BaseImporter
  def initialize(policy:)
    @policy = policy
    @records = []
    @logger = Logger.new($stdout)
    clear_data
    load_policies
    load_essential_fixtures
    read_test_csv
  end

  private

  attr_reader :policy, :records, :logger

  def clear_data
    Note.delete_all
    Task.delete_all
    Amendment.delete_all
    Decision.delete_all
    SupportTicket.delete_all
    Claim.delete_all
    EarlyCareerPayments::Eligibility.delete_all
    StudentLoans::Eligibility.delete_all
    MathsAndPhysics::Eligibility.delete_all
    Payment.delete_all
    PayrollRun.delete_all
    Reminder.delete_all
    DfeSignIn::User.delete_all
    School.delete_all
    LocalAuthorityDistrict.delete_all
    LocalAuthority.delete_all
    PolicyConfiguration.delete_all
  end

  def load_policies
    PolicyConfiguration.create!(policy_type: StudentLoans, current_academic_year: AcademicYear.current)
    PolicyConfiguration.create!(policy_type: MathsAndPhysics, current_academic_year: AcademicYear.current)
    PolicyConfiguration.create!(policy_type: EarlyCareerPayments, current_academic_year: AcademicYear.current)
  end

  def load_essential_fixtures
    ENV["FIXTURES_PATH"] = "spec/fixtures"
    ENV["FIXTURES"] = "local_authorities,local_authority_districts,schools"
    Rake::Task["db:fixtures:load"].invoke
  end

  def filename
    Rails.root.join("spec", "fixtures", "files", "dqt_testing", "ecp_test_seed_data_254_records.csv") if policy == EarlyCareerPayments
  end

  def read_test_csv
    logger.info "Reading csv data from #{filename}"
    CSV.foreach(filename, encoding: "iso-8859-1:utf-8", headers: true) do |row|
      @records << row
    end
  end

  def run_jobs
    logger.info "Clearing down Delayed::Jobs (worker)"
    Rake::Task["jobs:clear"].invoke
    claims = Claim.unsubmitted
    logger.info "Submitting #{claims.size} unsumitted claims for Claim Verification"
    claims.map(&:submit!)
    claims.each do |claim|
      ClaimVerifierJob.perform_later(claim)
    end

    Rake::Task["jobs:workoff"].invoke
  end
end
