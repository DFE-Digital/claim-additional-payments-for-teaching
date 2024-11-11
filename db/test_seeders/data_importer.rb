require_relative "seeder"
require_relative "base_importer"
require_relative "base_csv_import_validator"
require_relative "eligibilities/early_career_payments"
require_relative "eligibilities/early_career_payments/importer"
require_relative "eligibilities/early_career_payments/csv_import_validator"
require_relative "eligibilities/student_loans"
require_relative "eligibilities/student_loans/importer"
require_relative "eligibilities/student_loans/csv_import_validator"
require_relative "claims_importer"
require_relative "decisions_importer"
require_relative "record_builder"

class DataImporter < BaseImporter
  def initialize(policies:, **kwargs)
    super
  end

  def run
    policies.each do |policy|
      logger.info BOLD_LINE
      if [Policies::EarlyCareerPayments, Policies::StudentLoans].include?(policy)
        @policy = policy
        logger.info policy.to_s
      else
        logger.warn "#{FAILURE} #{policy} Policy not supported."
        break
      end
      if test_type == :volume
        @quantity = quantities[policy.to_s.underscore.to_sym]
        if quantity.to_i.zero?
          logger.info "0 #{policy} records requested !"
          break
        end
        self.records = RecordBuilder.new(quantity: quantity).records
      elsif test_type == :dqt_csv
        read_test_csv
      end

      insert_eligibilities
      logger.info LINE
      insert_claims
      submit_claims
      run_jobs
      validate_import
    end
    approve_and_generate_payroll
    logger.info BOLD_LINE
  end

  private

  attr_reader :eligibilities
  attr_accessor :records

  def insert_eligibilities
    case policy
    when Policies::EarlyCareerPayments
      if test_type == :dqt_csv
        TestSeeders::Eligibilities::EarlyCareerPayments::Importer.new(records).run
      elsif test_type == :volume
        TestSeeders::Eligibilities::EarlyCareerPayments::Importer.new(records, test_type: test_type, quantity: quantity).run
      end
      @eligibilities = Policies::EarlyCareerPayments::Eligibility.order(created_at: :asc).to_a
    when StudentLoans
      TestSeeders::Eligibilities::StudentLoans::Importer.new(records).run
      @eligibilities = Policies::StudentLoans::Eligibility.order(created_at: :asc).to_a
    end
  end

  def insert_claims
    TestSeeders::ClaimsImporter.new(records, eligibilities).run
  end

  def validate_import
    return unless test_type == :dqt_csv

    case policy
    when Policies::EarlyCareerPayments
      TestSeeders::Eligibilities::EarlyCareerPayments::CsvImportValidator.new(records, policy).run
    when StudentLoans
      TestSeeders::Eligibilities::StudentLoans::CsvImportValidator.new(records, policy).run
    end
  end

  def approve_and_generate_payroll
    return if test_type == :dqt_csv

    logger.info BOLD_LINE
    logger.info "Post Submission steps"
    insert_decisions
    generate_payroll
  end

  def insert_decisions
    claim_ids = Claim.awaiting_decision.ids
    return if claim_ids.empty?

    logger.info "Approving claims - #{admin_approver.role_codes.first}"
    TestSeeders::DecisionsImporter.new(claim_ids, admin_approver).run
  end

  def generate_payroll
    payrollable_claims ||= Claim.payrollable
    topups = []
    logger.info "Generating payroll for #{payrollable_claims.size} payments"

    payroll_run = PayrollRun.create!(created_by: @signed_in_user)
    PayrollRunJob.perform_now(payroll_run, payrollable_claims.ids, topups.map(&:id))
  end
end
