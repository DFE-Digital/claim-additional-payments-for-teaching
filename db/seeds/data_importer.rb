require_relative "base_importer"
require_relative "eligibilities/early_career_payments_seeder"
require_relative "claims_seeder"

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
      Seeds::Eligibilities::EarlyCareerPaymentsSeeder.new(records).run if policy == EarlyCareerPayments
      @eligibilities = EarlyCareerPayments::Eligibility.order(created_at: :desc).to_a
    end
  end

  def insert_claims
    Seeds::ClaimsSeeder.new(records, eligibilities).run
  end
end
