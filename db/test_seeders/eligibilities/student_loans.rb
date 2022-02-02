module TestSeeders
  module Eligibilities
    module StudentLoans
      extend self

      def build_subjects_taught(data)
        subjects_taught = {
          biology_taught: false,
          chemistry_taught: false,
          physics_taught: false,
          computing_taught: false,
          languages_taught: false
        }

        case find_eligible_itt_subject(data["Subject Code"])
        when :physics
          subjects_taught[:physics_taught] = true
        when :foreign_languages
          subjects_taught[:languages_taught] = true
        when :chemistry
          subjects_taught[:chemistry_taught] = true
        else # :mathematics
          subject = %i[biology computing].sample
          subjects_taught[:"#{subject}_taught"] = true
        end
        subjects_taught
      end

      def find_eligible_itt_subject(subject_code)
        ::EarlyCareerPayments::DqtRecord::ELIGIBLE_JAC_CODES.find { |key, values|
          subject_code.start_with?(*values)
        }&.first ||
          ::EarlyCareerPayments::DqtRecord::ELIGIBLE_HECOS_CODES.find { |key, values|
            values.include?(subject_code)
          }&.first
      end
    end
  end
end
