module Policies
  module TargetedRetentionIncentivePayments
    class StriDqtRecord
      attr_reader :record, :answers

      def initialize(record, answers)
        @record = record
        @answers = answers
      end

      def qts_award_date
        record.qts_award_date
      end

      # returns a date
      # relevant date of qualification for eligibility purposes
      # different qualifications use different date data point
      def academic_date
        record.held_routes_to_professional_statuses.map do |route|
          case route.qualification
          when :undergraduate_itt, :assessment_only, :overseas_recognition, :postgraduate_itt
            return qts_award_date
          end
        end.compact.max
      end

      # return an AcademicYear
      # based on academic_date determine the relevant AcademicYear
      # for eligibility purposes
      def academic_year_started_teaching
        AcademicYear.for(record.qts_award_date)
      end

      # QTS award date must be before the AY window opens
      # AND be within 5 years
      def qts_years_exceeded?
        return true if academic_year_started_teaching.blank?

        current_academic_year = Journeys::SchoolTargetedRetentionIncentivePayments.configuration.current_academic_year

        academic_year_started_teaching.start_year < (current_academic_year - 5).start_year
      end

      def qts_years_too_early?
        return true if academic_year_started_teaching.blank?

        current_academic_year = Journeys::SchoolTargetedRetentionIncentivePayments.configuration.current_academic_year

        academic_year_started_teaching.start_year >= (current_academic_year).start_year
      end

      def qualification_eligible?
        record.held_routes_to_professional_statuses.any? do |route|
          route.eligible_stri_qualification?
        end
      end

      def subject_eligible?
        record.held_routes_to_professional_statuses.any? do |route|
          route.eligible_stri_subject?
        end
      end

      def degree_code_eligible?
        degree_codes = DqtHigherEducationQualification.where(
          teacher_reference_number: record.teacher_reference_number,
          date_of_birth: record.date_of_birth
        ).pluck(:subject_code)

        (DqtRecord::ELIGIBLE_CODES & degree_codes).any?
      end
    end
  end
end
