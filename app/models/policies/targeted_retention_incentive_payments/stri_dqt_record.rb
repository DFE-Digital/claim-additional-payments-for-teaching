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
          when :undergraduate_itt, :assessment_only, :overseas_recognition
            return qts_award_date
          when :postgraduate_itt
            # For Postgraduate programs, the ITT start date is sometimes recorded a few days before the beginning of the
            # new academic year, which makes it fall, mistakenly, within the *previous* academic year. Based on the
            # situation, this can also cause the qualifications and induction checks to pass or fail automatically when
            # they shouldn't. One way around it is to assume that the new academic year can start up to 2 weeks earlier.
            if start_date&.between?(Date.new(route.start_date.year, 8, 18), Date.new(route.start_date.year, 8, 31))
              Date.new(route.start_date.year, 9, 1)
            else
              route.start_date
            end
          end
        end.compact.max
      end

      # return an AcademicYear
      # based on academic_date determine the relevant AcademicYear
      # for eligibility purposes
      def academic_year_started_teaching
        AcademicYear.for(academic_date)
      end

      def stri_eligible?
        qualification_eligible?
          && starting_teaching_year_eligible?
          && subject_eligible?
      end

      def starting_teaching_year_eligible?
        return false if academic_year_started_teaching.blank?

        current_academic_year = Journeys::SchoolTargetedRetentionIncentivePayments.configuration.current_academic_year

        academic_year_started_teaching >= current_academic_year - 5
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
    end
  end
end
