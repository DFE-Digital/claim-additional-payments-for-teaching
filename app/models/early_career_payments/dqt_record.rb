module EarlyCareerPayments
  class DqtRecord
    attr_reader :qts_award_date, :itt_subject_codes, :degree_codes

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

    def initialize(record, claim)
      @claim = claim
      @qts_award_date = record.fetch(:qts_date)
      @itt_subject_codes = record.fetch(:itt_subject_codes)
      @degree_codes = record.fetch(:degree_codes)
    end

    def eligible?
      award_amount = Eligibility::AWARD_AMOUNTS.find do |award_amount|
        itt_subject_group == award_amount.itt_subject &&
          AcademicYear.for(qts_award_date) == award_amount.itt_academic_year &&
          claim.academic_year == award_amount.claim_academic_year
      end

      !award_amount.nil?
    end

    def eligible_qts_date?
      eligible?
    end

    def eligible_qualification_subject?
      eligible?
    end

    private

    attr_reader :claim

    def itt_subject_group
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
