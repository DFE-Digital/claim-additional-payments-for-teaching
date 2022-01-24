module Seeds
  module Eligibilities
    class EarlyCareerPaymentsSeeder
      ELIGIBILITY_COLUMNS = [
        :nqt_in_academic_year_after_itt,
        :qualification,
        :eligible_itt_subject,
        :itt_academic_year,
        :teaching_subject_now,
        :employed_as_supply_teacher,
        :subject_to_disciplinary_action,
        :subject_to_formal_performance_action,
        :current_school_id,
        :created_at,
        :updated_at
      ].freeze

      def initialize(records)
        @records = records
        @logger = Logger.new($stdout)
      end

      def run
        logger.info "seeding #{records.size} ECP Eligibilities"
        insert_eligibilities
      end

      private

      attr_reader :records, :logger

      # the existing version of the activerecord-copy gem does not support
      # binary copy of decimals, so for now 'award_amount' has been excluded
      # it will be calculated dynamically, and because this is for test purposes
      # does not suffer the issue previously where if GIAS data changes then a
      # claimants award_amount might change between submission, approval and then
      # being added to a payroll run
      def insert_eligibilities
        EarlyCareerPayments::Eligibility.copy_from_client ELIGIBILITY_COLUMNS do |copy|
          records.each do |data|
            time = Time.now.getutc

            copy << [
              true,
              qualification(data["Post / Undergraduate / AO / Overseas"]),
              eligible_itt_subject(data["Subject Code"]),
              itt_academic_year(data["ITT Cohort Year"]),
              true,
              false,
              false,
              false,
              "c3a72961-340d-5e01-8fe0-73058c8e2f38",
              time,
              time
            ]
          end
        end
      end

      def qualification(route_into_teaching)
        EarlyCareerPayments::Eligibility.qualifications.find do |k, v|
          k.starts_with?(route_into_teaching.downcase.split.first)
        end&.last
      end

      def itt_academic_year(cohort_year)
        cohort_year.split("-").join("/")
      end

      def eligible_itt_subject(subject_code)
        eligible_itt_subject = find_eligible_itt_subject(subject_code)
        map_eligible_itt_subject_to_enum(eligible_itt_subject).to_s
      end

      def find_eligible_itt_subject(subject_code)
        EarlyCareerPayments::DqtRecord::ELIGIBLE_JAC_CODES.find { |key, values|
          subject_code.start_with?(*values)
        }&.first ||
          EarlyCareerPayments::DqtRecord::ELIGIBLE_HECOS_CODES.find { |key, values|
            values.include?(subject_code)
          }&.first
      end

      def map_eligible_itt_subject_to_enum(itt_subject)
        EarlyCareerPayments::Eligibility.eligible_itt_subjects.find do |key, values|
          key.include?(itt_subject.to_s)
        end&.last
      end
    end
  end
end
