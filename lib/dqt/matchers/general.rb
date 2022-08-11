module Dqt
  module Matchers
    module General
      QUALIFICATION_MATCHING_TYPE = {
        postgraduate_itt: [
          nil,
          "Degree",
          "Degree Equivalent (this will include foreign qualifications)",
          "Flexible - PGCE",
          "Flexible - ProfGCE",
          "Graduate Certificate in Education",
          "Graduate Diploma",
          "GTP",
          "Masters, not by research",
          "Postgraduate Certificate in Education",
          "Postgraduate Certificate in Education (Flexible)",
          "Postgraduate Diploma in Education",
          "Professional Graduate Certificate in Education",
          "Professional Graduate Diploma in Education",
          "Teach First",
          "Teach First (TNP)",
          "Teachers Certificate",
          "Unknown"
        ],
        undergraduate_itt: [
          "BA",
          "BA (Hons)",
          "BA (Hons) Combined Studies/Education of the Deaf",
          "BA/Education (QTS)",
          "BEd",
          "BEd (Hons)",
          "BSc",
          "BSc (Hons)",
          "BSc (Hons) with Intercalated PGCE",
          "BSc/Education (QTS)",
          "Undergraduate Master of Teaching"
        ],
        assessment_only: [
          "QTS Assessment only",
          "QTS Award only"
        ],
        overseas_recognition: [
          "EEA",
          "Northern Ireland",
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

      def eligible_subject?
        (ELIGIBLE_ITT_SUBJECTS[claim.eligibility.eligible_itt_subject.to_sym] & itt_subjects).any?
      end
    end
  end
end
