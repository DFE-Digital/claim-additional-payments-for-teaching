module Dqt
  module Matchers
    module General
      QUALIFICATION_MATCHING_TYPE = {
        postgraduate_itt: [
          "Core",
          "Flexible ITT",
          "Future Teaching Scholars",
          "Graduate non-trained",
          "Graduate Teacher Programme",
          "HEI",
          "HEI - Historic",
          "High Potential ITT",
          "Legacy ITT",
          "Legacy Migration",
          "Licensed Teacher Programme",
          "Licensed Teacher Programme - Armed Forces",
          "Licensed Teacher Programme - FE",
          "Licensed Teacher Programme - Independent School",
          "Licensed Teacher Programme - Maintained School",
          "Overseas Trained Teacher Programme",
          "PGATC ITT",
          "PGATD ITT",
          "PGCE ITT",
          "PGDE ITT",
          "Postgraduate Teaching Apprenticeship",
          "Primary and secondary postgraduate fee funded",
          "ProfGCE ITT",
          "ProfGDE ITT",
          "Provider led Postgrad",
          "School Centered ITT",
          "School Direct Training Programme",
          "School Direct Training Programme Salaried",
          "School Direct Training Programme Self Funded",
          "TC ITT",
          "TCMH",
          "Teach First Programme"
        ].map(&:downcase),
        undergraduate_itt: [
          "Primary and secondary undergraduate fee funded",
          "Provider led Undergrad",
          "Registered Teacher Programme",
          "Teacher Degree Apprenticeship",
          "Troops to Teach",
          "UGMT ITT",
          "Undergraduate Opt In"
        ].map(&:downcase),
        assessment_only: [
          "Assessment Only",
          "Long Service",
          "Other Qualifications non ITT"
        ].map(&:downcase),
        overseas_recognition: [
          "Apply for Qualified Teacher Status in England",
          "EC directive",
          "European Recognition",
          "European Recognition - PQTS",
          "International Qualified Teacher Status",
          "Licensed Teacher Programme - OTT",
          "Northern Irish Recognition",
          "Overseas Trained Teacher Recognition",
          "Scottish Recognition",
          "Welsh Recognition"
        ].map(&:downcase)
      }.freeze

      def academic_date
        case route_into_teaching
        when :undergraduate_itt, :assessment_only, :overseas_recognition
          qts_award_date
        when :postgraduate_itt
          # For Postgraduate programs, the ITT start date is sometimes recorded a few days before the beginning of the
          # new academic year, which makes it fall, mistakenly, within the *previous* academic year. Based on the
          # situation, this can also cause the qualifications and induction checks to pass or fail automatically when
          # they shouldn't. One way around it is to assume that the new academic year can start up to 2 weeks earlier.
          if itt_start_date&.between?(Date.new(itt_start_date.year, 8, 18), Date.new(itt_start_date.year, 8, 31))
            Date.new(itt_start_date.year, 9, 1)
          else
            itt_start_date
          end
        end
      end

      def itt_year
        @itt_year ||= AcademicYear.for(academic_date)
      end

      def eligible_qualification?
        QUALIFICATION_MATCHING_TYPE[qualification.to_sym].include?(qualification_name&.downcase)
      end

      def qts_award_date_after_itt_start_date?
        return true unless route_into_teaching == :postgraduate_itt
        return false if qts_award_date.blank?

        qts_award_date > itt_start_date
      end

      def route_into_teaching
        QUALIFICATION_MATCHING_TYPE.find do |_category, values|
          values.include?(qualification_name&.downcase)
        end&.first
      end
    end
  end
end
