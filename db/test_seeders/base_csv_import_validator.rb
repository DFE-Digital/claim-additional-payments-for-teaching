module TestSeeders
  class BaseCsvImportValidator
    include Seeder

    def initialize(records, policy)
      @records = records
      @logger = Logger.new($stdout)
      @unmatched_records = []
      @policy = policy
    end

    private

    attr_reader :logger, :records, :unmatched_records, :policy

    def validate_claim_and_eligibility_match_csv_record(claim, record, idx)
      data = {}
      eligibility = claim.eligibility
      data[:row] = idx + 1 # as 1st row is header
      data[:csv_trn] = record["Trn"]
      trn_mismatch(data, claim, record)
      route_into_teaching_mismatch(data, eligibility, record)
      eligible_itt_subject_mismatch(data, eligibility, record)
      itt_academic_year_mismatch(data, eligibility, record)
      unmatched_records << data if data.size > 2
    end

    def import_status
      unsubmitted_count ||= Claim.unsubmitted.size
      if unmatched_records.empty? && unsubmitted_count == 0
        logger.info "#{PASS} #{policy} DqT CSV data successfully loaded"
      else
        logger.warn "#{FAILURE} #{policy} DqT CSV data mismtach!"
      end
      log_unmatched_records
      log_unsubmitted_records(unsubmitted_count)
    end

    def log_unmatched_records
      return if unmatched_records.empty?

      logger.warn LINE
      logger.warn "Unmatched #{unmatched_records.size} Records!"
      unmatched_records.each_with_index do |unmatched_record, idx|
        logger.warn "#{WARN} Row: #{unmatched_record[:row]} / Trn: #{unmatched_record[:csv_trn]} / Errors:"
        logger.warn "#{WARN_L2} Route into teaching:  [Claim] #{unmatched_record[:route_into_teaching][:claim]} / [CSV] #{unmatched_record[:route_into_teaching][:csv]}" if unmatched_record[:route_into_teaching]
        logger.warn "#{WARN_L2} ITT Academic Year:    [Claim] #{unmatched_record[:itt_academic_year][:claim]} / [CSV] #{unmatched_record[:itt_academic_year][:csv]}" if unmatched_record[:itt_academic_year]
        logger.warn "#{WARN_L2} Eligible ITT Subject: [Claim] #{unmatched_record[:eligible_itt_subject][:claim]} / [CSV] #{unmatched_record[:eligible_itt_subject][:csv]}" if unmatched_record[:eligible_itt_subject]
      end
    end

    def log_unsubmitted_records(count)
      return if count == 0

      logger.warn LINE
      logger.warn "#{count} Claim(s) not submitted (invalid)"
      Claim.unsubmitted.each do |unsubmitted_claim|
        unsubmitted_claim.valid?(:submit)
        records_with_unsubmitted_claims = records.find_index do |record|
          record["Trn"] == unsubmitted_claim.teacher_reference_number
        end
        logger.warn "#{WARN} Row: #{records_with_unsubmitted_claims + 1} / Trn: #{unsubmitted_claim.teacher_reference_number} / Error(s):"
        logger.warn "#{WARN_L2} \'#{unsubmitted_claim.errors.messages[:base].first}\'"
        logger.warn "#{WARN_L2} CSV ITT Cohort Year: #{records[records_with_unsubmitted_claims + 1]["ITT Cohort Year"]}"
      end
    end

    def trn_mismatch(data, claim, record)
      return if claim.teacher_reference_number == record["Trn"]

      data[:trn] = {
        claim: claim.teacher_reference_number,
        csv: record["Trn"]
      }
    end

    def route_into_teaching_mismatch(data, eligibility, record)
      return if eligibility.qualification == qualification(record["Post / Undergraduate / AO / Overseas"])&.first

      data[:route_into_teaching] = {
        claim: eligibility.qualification,
        csv: qualification(record["Post / Undergraduate / AO / Overseas"])&.first
      }
    end

    def eligible_itt_subject_mismatch(data, eligibility, record)
      return if eligibility.eligible_itt_subject == eligible_itt_subject(record["Subject Code"])&.first

      data[:eligible_itt_subject] = {
        claim: eligibility.eligible_itt_subject,
        csv: eligible_itt_subject(record["Subject Code"])&.first
      }
    end

    def itt_academic_year_mismatch(data, eligibility, record)
      return if eligibility.itt_academic_year == itt_academic_year(record["ITT Cohort Year"])

      data[:itt_academic_year] = {
        claim: eligibility.itt_academic_year.to_s,
        csv: itt_academic_year(record["ITT Cohort Year"])
      }
    end
  end
end
