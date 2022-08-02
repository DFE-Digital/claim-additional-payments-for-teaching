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

    def initialize(record, claim)
      @claim = claim
      @record = record
    end

    def eligible?
      matching_type = Dqt::Codes::QUALIFICATION_MATCHING_TYPE.find { |key, values|
        values.include?(qualification_name)
      }&.first

      date = case matching_type
      when :under, :other
        qts_award_date
      when :post
        itt_start_date
      end

      policy_year = claim.academic_year
      itt_year = AcademicYear.for(date)
      subject_symbol = itt_subject_group

      award_args = {policy_year: policy_year, itt_year: itt_year, subject_symbol: subject_symbol}

      if award_args.values.any?(&:blank?)
        false
      else
        AwardAmountCalculator.award?(award_args)
      end
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
            Dqt::Codes::ELIGIBLE_JAC_NAMES.find { |key, values|
              values.include?(subject_code)
            }&.first ||
            Dqt::Codes::ELIGIBLE_HECOS_NAMES.find { |key, values|
              values.include?(subject_code)
            }&.first
      end
    end
  end
end
