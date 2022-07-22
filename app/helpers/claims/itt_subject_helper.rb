require "journey_subject_eligibility_checker"

module Claims
  module IttSubjectHelper
    def subject_symbols(current_claim)
      subjects = if trainee_teacher?(current_claim)
        # they get the standard, unchanging LUP subject set because they won't have qualified in time for ECP by 2022/2023
        # and they won't have given an ITT year
        if current_claim.policy_year.in?(EligibilityCheckable::COMBINED_ECP_AND_LUP_POLICY_YEARS_BEFORE_FINAL_YEAR)
          JourneySubjectEligibilityChecker.fixed_lup_subject_symbols
        else
          []
        end
      else
        JourneySubjectEligibilityChecker.new(claim_year: current_claim.policy_year, itt_year: itt_year(current_claim)).selectable_subject_symbols(current_claim)
      end

      # TODO this might not work when subject keys and display values diverge, like when
      # `Foreign Languages` changes to `Languages` in the GUI
      # but before we've had a chance to change the enum from `:foreign_languages` to `:languages`
      subjects.sort
    end

    def subjects_to_sentence(current_claim)
      ecp_only_subjects = [:foreign_languages]
      lup_only_subjects = [:computing]

      subject_selection = current_claim.eligibility.eligible_itt_subject
      hint_subject_symbols = subject_symbols(current_claim)

      if subject_selection.present?
        subject_selection_symbol = subject_selection.to_sym

        lup_claim_eligibility = current_claim.for_policy(LevellingUpPremiumPayments).eligibility
        ecp_claim_eligibility = current_claim.for_policy(EarlyCareerPayments).eligibility

        if subject_selection_symbol.in?(ecp_only_subjects) && lup_claim_eligibility.status == :ineligible
          hint_subject_symbols -= lup_only_subjects
        elsif subject_selection_symbol.in?(lup_only_subjects) && ecp_claim_eligibility.status == :ineligible
          hint_subject_symbols -= ecp_only_subjects
        end
      end

      hint_subject_symbols.map { |sub| t("early_career_payments.answers.eligible_itt_subject.#{sub}") }
        .sort
        .to_sentence(last_word_connector: " or ")
        .downcase
    end

    private

    # TODO: something like this could move to `CurrentClaim`
    def trainee_teacher?(current_claim)
      current_claim_non_nil_values_for_nqt_in_academic_year_after_itt = current_claim.claims.collect { |claim| claim.eligibility.nqt_in_academic_year_after_itt }.compact.to_set

      # one? doesn't work when dealing with enumerables of booleans
      if current_claim_non_nil_values_for_nqt_in_academic_year_after_itt.count == 1
        # doing something different here because we're checking it's not nqt_in_academic_year_after_itt
        current_claim_non_nil_values_for_nqt_in_academic_year_after_itt.first == false
      elsif current_claim_non_nil_values_for_nqt_in_academic_year_after_itt.many?
        raise "Claims eligibilities should have consistent nqt_in_academic_year_after_itt but had multiple: #{current_claim_non_nil_values_for_nqt_in_academic_year_after_itt}"
      else
        raise "Claims eligibilities didn't have any nqt_in_academic_year_after_itt set"
      end
    end

    # TODO: something like this could move to `CurrentClaim`
    def itt_year(current_claim)
      current_claim_non_nil_values_for_itt_academic_year = current_claim.claims.collect { |claim| claim.eligibility.itt_academic_year }.compact.to_set

      if current_claim_non_nil_values_for_itt_academic_year.count == 1
        current_claim_non_nil_values_for_itt_academic_year.first
      elsif current_claim_non_nil_values_for_itt_academic_year.many?
        raise "Claims eligibilities should have consistent itt_academic_year but had multiple: #{current_claim_non_nil_values_for_nqt_in_academic_year_after_itt}"
      else
        raise "Claims eligibilities didn't have any itt_academic_year set"
      end
    end
  end
end
