require "journey_subject_eligibility_checker"

module LevellingUpPremiumPayments
  class DqtRecord
    include Dqt::Matchers::General
    include Dqt::Matchers::LevellingUpPremiumPayments

    ELIGIBLE_CODES = ELIGIBLE_JAC_CODES | ELIGIBLE_HECOS_CODES

    delegate(
      :qts_award_date,
      :itt_subjects,
      :itt_subject_codes,
      :itt_start_date,
      :degree_codes,
      :degree_names,
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

      # In the absence of a valid ITT subject code or degree, the subject name
      # is checked against the list of eligible subjects; in this scenario,
      # there must be no invalid subject codes returned from the DQT.
      eligible_codes? || (eligible_subject? && no_invalid_subject_codes?)
    end

    def eligible_degree_code?
      eligible_code?(degree_codes)
    end

    def eligible_itt_subject_for_claim
      return nil if itt_subjects.empty?

      ELIGIBLE_ITT_SUBJECTS.detect { |k, v| !(v & itt_subjects).empty? }&.first || :none_of_the_above
    end

    def itt_academic_year_for_claim
      return nil unless academic_date

      year = AcademicYear.for(academic_date)
      itt_year_within_allowed_range?(year) ? year : AcademicYear.new
    end

    def has_no_data_for_claim?
      !eligible_itt_subject_for_claim && !itt_academic_year_for_claim && !route_into_teaching && !eligible_degree_code?
    end

    private

    attr_reader :record, :claim

    def eligible_code?(codes)
      (ELIGIBLE_CODES & codes).any?
    end

    def eligible_codes?
      eligible_code?(itt_subject_codes) || eligible_degree_code?
    end

    def eligible_subject_and_none_of_the_above?
      return false if claim.eligibility.itt_subject_none_of_the_above? && eligible_subject?
      return true if claim.eligibility.itt_subject_none_of_the_above?

      eligible_subject?
    end

    def eligible_itt_year?
      return unless super

      itt_year_within_allowed_range?
    end

    def applicable_eligible_subjects
      return ELIGIBLE_ITT_SUBJECTS.values.flatten if claim.eligibility.itt_subject_none_of_the_above?

      ELIGIBLE_ITT_SUBJECTS[claim.eligibility.eligible_itt_subject.to_sym]
    end

    def eligible_subject?
      (applicable_eligible_subjects & itt_subjects).any?
    end

    def no_invalid_subject_codes?
      (itt_subject_codes - ELIGIBLE_CODES).empty?
    end

    def itt_year_within_allowed_range?(year = itt_year)
      policy_year = JourneyConfiguration.for(claim.policy).current_academic_year
      eligible_itt_years = JourneySubjectEligibilityChecker.selectable_itt_years_for_claim_year(policy_year)
      eligible_itt_years.include?(year)
    end
  end
end
