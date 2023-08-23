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
      :induction_start_date,
      :induction_completion_date,
      :induction_status,
      to: :record
    )

    def initialize(record, claim)
      @claim = claim
      @record = record
    end

    def eligible?
      eligible_subject? &&
        eligible_qualification? &&
        eligible_itt_year? &&
        qts_award_date_after_itt_start_date? &&
        award_due?
    end

    def eligible_induction?
      InductionData.new(itt_year:, induction_status:, induction_start_date:).eligible?
    end

    private

    attr_reader :claim, :record

    def award_due?
      award_args = {policy_year: claim.academic_year, itt_year: itt_year, subject_symbol: itt_subject_group}

      if award_args.values.any?(&:blank?)
        false
      else
        AwardAmountCalculator.award?(**award_args)
      end
    end

    def itt_subject_group
      [*itt_subject_codes, *degree_codes, *itt_subjects].map do |subject_code|
        ELIGIBLE_JAC_CODES.find { |key, values| subject_code.start_with?(*values) }&.first ||
          ELIGIBLE_HECOS_CODES.find { |key, values| values.include?(subject_code) }&.first ||
          ELIGIBLE_JAC_NAMES.find { |key, values| values.include?(subject_code) }&.first ||
          ELIGIBLE_HECOS_NAMES.find { |key, values| values.include?(subject_code) }&.first
      end.compact.uniq.find do |group|
        group == claim.eligibility.eligible_itt_subject.to_sym
      end
    end

    def eligible_subject?
      (ELIGIBLE_ITT_SUBJECTS[claim.eligibility.eligible_itt_subject.to_sym] & itt_subjects).any?
    end
  end
end
