module TestSeeders
  module Eligibilities
    module StudentLoans
      extend self

      def qualification(route_into_teaching)
        ::StudentLoans::Eligibility.qualifications.find do |k, v|
          k.starts_with?(route_into_teaching.downcase.split.first)
        end
      end

      def build_subjects_taught(data)
        subjects_taught = {
          biology_taught: false,
          chemistry_taught: false,
          physics_taught: false,
          computing_taught: false,
          languages_taught: false
        }

        # case data
        # when eligible_itt_subject
        subjects_taught[:biology_taught] = true
        # end

        subjects_taught
      end
    end
  end
end
