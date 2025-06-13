module Dqt
  module Matchers
    module General
      QUALIFICATION_MATCHING_TYPE = {
        postgraduate_itt: [
          "Degree",
          "Degree Equivalent (this will include foreign qualifications)",
          "Flexible - Assessment Only",
          "Flexible - PGCE",
          "Flexible - ProfGCE",
          "Graduate Certificate in Education",
          "Graduate Diploma",
          "GTP",
          "Licensed Teacher Programme",
          "Masters, not by research",
          "OTT (Exempt From Induction)",
          "PGCE (Articled Teachers Scheme)",
          "Postgraduate Certificate in Education",
          "Postgraduate Certificate in Education (Flexible)",
          "Postgraduate Diploma in Education",
          "Professional Graduate Certificate in Education",
          "Professional Graduate Diploma in Education",
          "QTS Award",
          "Teach First",
          "Teach First (TNP)",
          "Teachers Certificate",
          "Unknown"
        ],
        undergraduate_itt: [
          "BA",
          "BA (Hons)",
          "BA (Hons) Combined Studies/Education of the Deaf",
          "BA (Hons) with Intercalated PGCE",
          "BA Combined Studies/Education of the Deaf",
          "BA with intercalated PGCE",
          "BA/Certificate in Education (QTS)",
          "BA/Education (QTS)",
          "BEd",
          "BEd (Hons)",
          "BSc",
          "BSc (Hons)",
          "BSc (Hons) with Intercalated PGCE",
          "BSc/Certificate in Education (QTS)",
          "BSc/Education (QTS)",
          "RTP",
          "Troops to Teach",
          "Undergraduate Master of Teaching"
        ],
        assessment_only: [
          "Assessment Only Route",
          "QTS Assessment only",
          "QTS Award only"
        ],
        overseas_recognition: [
          "EEA",
          "Northern Ireland",
          "Qualification gained in Europe",
          "OTT",
          "OTT Recognition",
          "Scotland"
        ]
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
        QUALIFICATION_MATCHING_TYPE[qualification.to_sym].include?(qualification_name)
      end

      def qts_award_date_after_itt_start_date?
        return true unless route_into_teaching == :postgraduate_itt
        return false if qts_award_date.blank?

        qts_award_date > itt_start_date
      end

      def route_into_teaching
        @route_into_teaching ||= begin
          # All the categories need to be browsed in order to estabilish the uniqueness of a match.
          # We cannot infer the correct category if a qualification is present in more than one category.
          match = QUALIFICATION_MATCHING_TYPE.select { |_, category| category.include?(qualification_name) }.keys
          (match.count == 1) ? match.first : nil
        end
      end
    end
  end
end
