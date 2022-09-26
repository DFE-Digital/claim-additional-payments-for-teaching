module Dqt
  module Matchers
    module General
      QUALIFICATION_MATCHING_TYPE = {
        postgraduate_itt: [
          nil,
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
        matching_type = QUALIFICATION_MATCHING_TYPE.find { |_key, values|
          values.include?(qualification_name)
        }&.first

        case matching_type
        when :undergraduate_itt, :assessment_only, :overseas_recognition
          qts_award_date
        when :postgraduate_itt
          itt_start_date
        end
      end

      def itt_year
        @itt_year ||= AcademicYear.for(academic_date)
      end

      def eligible_qualification?
        QUALIFICATION_MATCHING_TYPE[claim.eligibility.qualification.to_sym].include?(qualification_name)
      end

      def eligible_itt_year?
        AcademicYear.new(itt_year).eql?(claim.eligibility.itt_academic_year)
      end
    end
  end
end
