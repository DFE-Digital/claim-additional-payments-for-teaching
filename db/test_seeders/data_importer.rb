require_relative "base_importer"
require_relative "base_csv_import_validator"
require_relative "eligibilities/early_career_payments"
require_relative "eligibilities/early_career_payments/importer"
require_relative "eligibilities/early_career_payments/csv_import_validator"
require_relative "eligibilities/student_loans"
require_relative "eligibilities/student_loans/importer"
require_relative "eligibilities/student_loans/csv_import_validator"
require_relative "claims_importer"

class DataImporter < BaseImporter
  def initialize(policy:)
    super
  end

  def run
    insert_eligibilities
    insert_claims
    run_jobs
    validate_import
  end

  private

  attr_reader :eligibilities

  def insert_eligibilities
    case policy
    when EarlyCareerPayments
      TestSeeders::Eligibilities::EarlyCareerPayments::Importer.new(records).run
      @eligibilities = EarlyCareerPayments::Eligibility.order(created_at: :asc).to_a
    when StudentLoans
      TestSeeders::Eligibilities::StudentLoans::Importer.new(records).run
      @eligibilities = StudentLoans::Eligibility.order(created_at: :asc).to_a
    end
  end

  def insert_claims
    TestSeeders::ClaimsImporter.new(records, eligibilities).run
  end

  def validate_import
    case policy
    when EarlyCareerPayments
      TestSeeders::Eligibilities::EarlyCareerPayments::CsvImportValidator.new(records, policy).run
    when StudentLoans
      TestSeeders::Eligibilities::StudentLoans::CsvImportValidator.new(records, policy).run
    end
  end
end
