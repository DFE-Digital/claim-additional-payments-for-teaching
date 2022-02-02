require_relative "base_importer"
require_relative "eligibilities/early_career_payments_importer"
require_relative "claims_importer"

class DataImporter < BaseImporter
  def initialize(policy:)
    super
  end

  def run
    insert_eligibilities
    insert_claims
    run_jobs
  end

  private

  attr_reader :eligibilities

  def insert_eligibilities
    case policy
    when EarlyCareerPayments
      TestSeeders::Eligibilities::EarlyCareerPaymentsImporter.new(records).run
      @eligibilities = EarlyCareerPayments::Eligibility.order(created_at: :desc).to_a
    end
  end

  def insert_claims
    TestSeeders::ClaimsImporter.new(records, eligibilities).run
  end
end
