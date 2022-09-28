require "journey_subject_eligibility_checker"

module LevellingUpPremiumPayments
  class DqtRecord
    include Dqt::Matchers::General
    include Dqt::Matchers::LevellingUpPremiumPayments

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
      @record = record
      @claim = claim
    end

    def eligible?
      return false unless eligible_subject_and_none_of_the_above? &&
        eligible_qualification? &&
        eligible_itt_year? &&
        qts_award_date_after_itt_start_date?

      policy_year = PolicyConfiguration.for(claim.policy).current_academic_year
      eligible_itt_years = JourneySubjectEligibilityChecker.selectable_itt_years_for_claim_year(policy_year)

      (eligible_code?(itt_subject_codes) || eligible_code?(degree_codes)) && eligible_itt_years.include?(itt_year)
    end

    private

    attr_reader :record, :claim

    def eligible_code?(code)
      ((Dqt::Matchers::LevellingUpPremiumPayments::ELIGIBLE_JAC_CODES | Dqt::Matchers::LevellingUpPremiumPayments::ELIGIBLE_HECOS_CODES) & code).any?
    end

    def eligible_subject_and_none_of_the_above?
      return false if claim.eligibility.itt_subject_none_of_the_above? && (ELIGIBLE_ITT_SUBJECTS.values.flatten & itt_subjects).any?
      return true if claim.eligibility.itt_subject_none_of_the_above?

      (ELIGIBLE_ITT_SUBJECTS[claim.eligibility.eligible_itt_subject.to_sym] & itt_subjects).any?
    end
  end
end
