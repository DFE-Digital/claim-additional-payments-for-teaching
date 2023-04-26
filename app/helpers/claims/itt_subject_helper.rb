require "journey_subject_eligibility_checker"

module Claims
  module IttSubjectHelper
    def subject_symbols(current_claim)
      subjects = if current_claim.eligibility.nqt_in_academic_year_after_itt
        JourneySubjectEligibilityChecker.new(claim_year: current_claim.policy_year, itt_year: current_claim.eligibility.itt_academic_year).selectable_subject_symbols(current_claim)
      elsif current_claim.policy_year.in?(EligibilityCheckable::COMBINED_ECP_AND_LUP_POLICY_YEARS_BEFORE_FINAL_YEAR)
        # they get the standard, unchanging LUP subject set because they won't have qualified in time for ECP by 2022/2023
        # and they won't have given an ITT year
        JourneySubjectEligibilityChecker.fixed_lup_subject_symbols
      else
        []
      end

      subjects.sort
    end

    def subjects_to_sentence_for_hint_text(current_claim)
      all_ecp_subjects = [:chemistry, :foreign_languages, :mathematics, :physics]
      all_lup_subjects = JourneySubjectEligibilityChecker.fixed_lup_subject_symbols

      hint_subject_symbols = Set[]

      if current_claim.eligibility.nqt_in_academic_year_after_itt
        potentially_eligible_for_ecp = ![:ineligible, :eligible_later].include?(current_claim.for_policy(EarlyCareerPayments).eligibility.status)
        potentially_eligible_for_lup = current_claim.for_policy(LevellingUpPremiumPayments).eligibility.status != :ineligible

        hint_subject_symbols.merge(all_ecp_subjects) if potentially_eligible_for_ecp
        hint_subject_symbols.merge(all_lup_subjects) if potentially_eligible_for_lup
      else
        hint_subject_symbols.merge(all_lup_subjects)
      end

      hint_subject_symbols.map { |sub| t("early_career_payments.answers.eligible_itt_subject.#{sub}") }
        .sort
        .to_sentence(last_word_connector: " or ")
        .downcase
    end
  end
end
