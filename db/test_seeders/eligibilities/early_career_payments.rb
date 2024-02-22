module TestSeeders
  module Eligibilities
    module EarlyCareerPayments
      extend self

      def qualification(route_into_teaching)
        ::EarlyCareerPayments::Eligibility.qualifications.find do |k, v|
          k.starts_with?(route_into_teaching.downcase.split.first)
        end
      end

      def itt_academic_year(cohort_year)
        cohort_year.split("-").join("/")
      end

      def eligible_itt_subject(subject_code)
        eligible_itt_subject = find_eligible_itt_subject(subject_code)
        map_eligible_itt_subject_to_enum(eligible_itt_subject)
      end

      def find_eligible_itt_subject(subject_code)
        Policies::EarlyCareerPayments::DqtRecord::ELIGIBLE_JAC_CODES.find { |key, values|
          subject_code.start_with?(*values)
        }&.first ||
          Policies::EarlyCareerPayments::DqtRecord::ELIGIBLE_HECOS_CODES.find { |key, values|
            values.include?(subject_code)
          }&.first
      end

      def map_eligible_itt_subject_to_enum(itt_subject)
        ::EarlyCareerPayments::Eligibility.eligible_itt_subjects.find do |key, values|
          key.include?(itt_subject.to_s)
        end
      end
    end
  end
end
