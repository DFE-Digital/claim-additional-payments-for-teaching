module EarlyCareerPayments
  class DqtRecord
    delegate(
      :qts_award_date,
      :itt_subjects,
      :itt_subject_codes,
      :itt_start_date,
      :degree_codes,
      :qualification_name,
      to: :record
    )

    ELIGIBLE_JAC_CODES = {
      chemistry: %w[
        F1
      ],
      foreign_languages: %w[
        Q1
        Q4
        Q5
        Q6
        Q7
        Q8
        Q9
        R1
        R2
        R3
        R4
        R5
        R6
        R7
        R8
        R9
        T1
        T2
        T4
        T5
        T6
        T7
        T8
        Z0
        ZZ
      ],
      mathematics: %w[
        G1
        G4
        G5
        G9
      ],
      physics: %w[
        F3
        F6
        F9
      ]
    }.freeze

    # match HECOS NAMES to all codes in order
    ELIGIBLE_HECOS_CODES = {
      chemistry: %w[
        100417
        101038
      ],
      foreign_languages: %w[
        100321
        100323
        100326
        100329
        100330
        100332
        100333
        101142
        101420
      ],
      mathematics: %w[
        100403
      ],
      physics: %w[
        100425
        101060
      ]
    }.freeze

    # match JAC CODES to all names in order
    ELIGIBLE_JAC_NAMES = {
      chemistry: [
        # F1
        "Applied Chemistry",
        "Applied Chemistry",
        "Chemical Sciences",
        "Chemical Technology",
        "Chemistry",
        "Environmental Chemistry",
        "Inorganic Chemistry",
        "Science-Chemistry-Bath Ude"
      ],
      foreign_languages: [
        # Q1
        "Foreign & Community Languages",
        "Foreign Languages",
        # Q4
        "Ancient language studies not elsewhere classified",
        # Q5
        "Celtic Languages",
        "Gaelic",
        "Irish",
        "Ling,lit & Cult Herit-Welsh",
        "Welsh",
        "Welsh and Drama",
        "Welsh and Welsh Studies",
        "Welsh As A Modern Language",
        "Welsh As A Second Language",
        "Welsh Literature",
        "Welsh Studies",
        # Q6
        "Latin",
        "Latin Language",
        # Q7
        "Ancient Greek",
        "Classical Greek Language",
        "Greek (Classical)",
        # Q8
        "Ancient Greek Lang & Lit",
        "Classical Languages",
        # Q9
        "French and Spanish",
        "German With French",
        "Mfl(French, Spanish, German)",
        "Spanish With French",
        "Teach Eng -Speakers Other Lang",
        # R1
        "French",
        "French and German",
        "French Lang and Literature",
        "French Language & Studies",
        "French Literature",
        "French Studies (In Translation)",
        "Frenchlang and Contemp Studs",
        # R2
        "German",
        "German Language & Studies",
        "German Literature",
        # R3
        "Italian",
        "Italian Language & Studies",
        # R4
        "Hispanic",
        "Hispanic Studies",
        "Spanish",
        "Spanish Language & Studies",
        "Spanish Studies (In Translation)",
        # R5
        "Portuguese", # F500
        "Portuguese", # F5000
        # R6
        "Latin American Languages",
        # R7
        "Danish",
        "Norwegian",
        "Russian",
        "Swedish",
        # R8
        "Modern Foreign Languages",
        "French Lang, Lit & Cult",
        "French With German",
        "French With Italian",
        "French With Russian",
        "French With Spanish",
        "German Lang, Lit & Cult",
        "Italian Lang, Lit & Cult",
        "Latin Amcn Lang, Lit & Cult",
        "Portuguese Lang, Lit & Cult",
        "Russian Lang, Lit & Cult",
        "Russian Language & Studies",
        "Russian With German",
        "Scandinavian Lang, Lit & Cult",
        "Spanish Lang, Lit & Cult",
        # R9
        "Other Modern Language",
        # T1
        "Czech",
        # T2
        "Dutch",
        "Modern and Community Langs",
        "Modern Greek",
        "Modern Languages",
        # T4
        "Japanese",
        # T5
        "Asian Languages",
        "Gujarati",
        "Urdu",
        # T6
        "Arabic",
        "Turkish",
        # T7
        "Afrikaans",
        # T8
        "Gen Asian Lang, Lit & Cult",
        "Gen Euro Lang, Lit & Cult",
        "Gen Modern Languages",
        "General Language Studies",
        "Japanese Lang, Lit & Cult",
        # Z0
        "Spanish (And Studies)",
        "Welsh and Other Celtic Lang",
        # ZZ
        "Austrian",
        "Bengali",
        "Chinese",
        "Hindi",
        "Icelandic",
        "Modern Hebrew",
        "Punjabi"
      ],
      mathematics: [
        # G1
        "Mathematics",
        "Applied Mathematics",
        "Mathematical Education",
        "Mathematical Science",
        "Mathematical Studies",
        "Maths.Science and Technology",
        "Pure Mathematics",
        # G4
        "Statistics",
        "Operational Rsearch Techniques",
        # G5
        "Technological Mathematics",
        "Mathematics & Computer Studies",
        "Maths.Stats. and Computing",
        # G9
        "Mathematics and Science",
        "Maths and Info. Technology",
        "Maths With Computer Science",
        "Numeracy",
        "Technology and Mathematics"
      ],
      physics: [
        # F3
        "Applied Physics",
        "Chemical Physics",
        "Mathematical Physics",
        "Mechanics",
        "Natural Philosophy",
        "Physics",
        "Physics with Maths",
        "Science-Physics-Bath Ude",
        "Theoretical Physics",
        # F6
        "Physics With Technology",
        "Physics/Engineering Science",
        # F9
        "Physics (With Science)",
        "Physics and Science",
        "Physics With Core Science"
      ]
    }.freeze

    ELIGIBLE_HECOS_NAMES = {
      chemistry: [
        "chemistry",
        "applied chemistry"
      ],
      foreign_languages: [
        "French language",
        "German language",
        "Italian language",
        "modern languages",
        "Russian languages",
        "Spanish language",
        "Welsh language",
        "Portuguese language",
        "Latin language"
      ],
      mathematics: %w[
        mathematics
      ],
      physics: [
        "physics",
        "applied physics"
      ]
    }.freeze

    QUALIFICATON_MATCHING_TYPE = {
      post: [
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
      under: [
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
      other: [
        "EEA",
        "Northern Ireland",
        "OTT",
        "OTT Recognition",
        "QTS Assessment only",
        "QTS Award only",
        "Scotland"
      ]
    }.freeze

    def initialize(record, claim)
      @claim = claim
      @record = record
    end

    def eligible?
      award_amount = Eligibility::AWARD_AMOUNTS.find do |award_amount|
        matching_type = QUALIFICATON_MATCHING_TYPE.find { |key, values|
          values.include?(qualification_name)
        }&.first

        date =
          if matching_type == :under || matching_type == :other
            qts_award_date
          elsif matching_type == :post
            itt_start_date
          end

        itt_subject_group == award_amount.itt_subject &&
          AcademicYear.for(date) == award_amount.itt_academic_year &&
          claim.academic_year == award_amount.claim_academic_year
      end

      !award_amount.nil?
    end

    private

    attr_reader :claim, :record

    def itt_subject_group
      [*itt_subject_codes, *degree_codes, *itt_subjects].each do |subject_code|
        return ELIGIBLE_JAC_CODES.find { |key, values|
          subject_code.start_with?(*values)
        }&.first ||
            ELIGIBLE_HECOS_CODES.find { |key, values|
              values.include?(subject_code)
            }&.first ||
            ELIGIBLE_JAC_NAMES.find { |key, values|
              values.include?(subject_code)
            }&.first ||
            ELIGIBLE_HECOS_NAMES.find { |key, values|
              values.include?(subject_code)
            }&.first
      end
    end
  end
end
