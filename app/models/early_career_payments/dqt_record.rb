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

    def eligible_qts_award_date?
      eligible?
    end

    def eligible_qualification_subject?
      eligible?
    end

    private

    attr_reader :claim, :record

    def itt_subject_group
      return itt_subjects.first.downcase.tr(" ", "_").to_sym if itt_subjects.present? && itt_subject_codes.blank?

      [*itt_subject_codes, *degree_codes].each do |subject_code|
        return ELIGIBLE_JAC_CODES.find { |key, values|
          subject_code.start_with?(*values)
        }&.first ||
            ELIGIBLE_HECOS_CODES.find { |key, values|
              values.include?(subject_code)
            }&.first
      end
    end
  end
end
