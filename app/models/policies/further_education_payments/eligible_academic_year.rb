module Policies
  module FurtherEducationPayments
    class EligibleAcademicYear
      def initialize(candidate_academic_year:, current_academic_year:)
        @candidate_academic_year = AcademicYear.wrap(candidate_academic_year)
        @current_academic_year = AcademicYear.wrap(current_academic_year)
      end

      def eligible?
        eligible_academic_years.include?(@candidate_academic_year)
      end

      def to_s
        if eligible?
          I18n.t(
            "further_education_payments.forms.further_education_teaching_start_year.options.between_dates",
            start_year: @candidate_academic_year.start_year,
            end_year: @candidate_academic_year.end_year
          )
        else
          "Before September #{before_year.start_year}"
        end
      end

      private

      def eligible_academic_years
        Policies::FurtherEducationPayments
          .selectable_teaching_start_academic_years(@current_academic_year)
      end

      def before_year
        eligible_academic_years.first
      end
    end
  end
end
