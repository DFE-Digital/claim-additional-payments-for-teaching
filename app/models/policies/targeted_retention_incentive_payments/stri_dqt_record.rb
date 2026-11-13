module Policies
  module TargetedRetentionIncentivePayments
    class StriDqtRecord
      attr_reader :record

      def initialize(record)
        @record = record
      end

      # QTS award date must be before the AY window opens
      # AND be within 5 years
      def qts_years_exceeded?
        return true if academic_year_awarded_qts.blank?

        current_academic_year = Journeys::SchoolTargetedRetentionIncentivePayments.configuration.current_academic_year

        academic_year_awarded_qts.start_year < (current_academic_year - 5).start_year
      end

      def qts_years_too_early?
        return true if academic_year_awarded_qts.blank?

        current_academic_year = Journeys::SchoolTargetedRetentionIncentivePayments.configuration.current_academic_year

        academic_year_awarded_qts.start_year >= current_academic_year.start_year
      end

      def qualification_eligible?
        record.held_routes_to_professional_statuses.any? do |route|
          route.eligible_stri_qualification?
        end
      end

      def subject_eligible?
        record.held_routes_to_professional_statuses.any? do |route|
          route.eligible_stri_subject_by_code? || route.eligible_stri_subject_by_name?
        end
      end

      def degree_code_eligible?
        degree_codes = DqtHigherEducationQualification.where(
          teacher_reference_number: record.teacher_reference_number,
          date_of_birth: record.date_of_birth
        ).pluck(:subject_code)

        (DqtRecord::ELIGIBLE_CODES & degree_codes).any?
      end

      private

      def qts_award_date
        record.qts_award_date
      end

      def academic_year_awarded_qts
        AcademicYear.for(qts_award_date)
      end
    end
  end
end
