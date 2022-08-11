module EarlyCareerPayments
  class DqtRecord
    include Dqt::Matchers::General
    include Dqt::Matchers::EarlyCareerPayments

    delegate(
      :qts_award_date,
      :itt_subjects,
      :itt_subject_codes,
      :itt_start_date,
      :degree_codes,
      :qualification_name,
      to: :record
    )

    def initialize(record, claim)
      @claim = claim
      @record = record
    end

    def eligible?
      return false unless eligible_subject? && eligible_qualification? && eligible_itt_year?

      award_args = {policy_year: claim.academic_year, itt_year: itt_year, subject_symbol: itt_subject_group}

      if award_args.values.any?(&:blank?)
        false
      else
        AwardAmountCalculator.award?(award_args)
      end
    end

    private

    attr_reader :claim, :record

    # TODO: This method needs some investigation.
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

    def eligible_subject?
      (ELIGIBLE_ITT_SUBJECTS[claim.eligibility.eligible_itt_subject.to_sym] & itt_subjects).any?
    end
  end
end
