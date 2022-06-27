require "journey_subject_eligibility_checker"

module Claims
  module IttSubjectHelper
    def subject_symbols(current_claim)
      subjects = if trainee_teacher?(current_claim)
        # they get the standard, unchanging LUP subject set because they won't have qualified in time for ECP by 2022/2023
        [:chemistry, :computing, :mathematics, :physics]
      else
        current_policy_year = current_policy_year(current_claim)
        JourneySubjectEligibilityChecker.new(claim_year: current_policy_year(current_claim), itt_year: itt_year(current_claim)).selectable_subject_symbols(current_claim)
      end

      # TODO this might not work when subject keys and display values diverge, like when
      # `Foreign Languages` changes to `Languages` in the GUI
      # but before we've had a chance to change the enum from `:foreign_languages` to `:languages`
      subjects.sort
    end

    def subjects_to_sentence(current_claim)
      subject_symbols(current_claim).map { |sub| t("early_career_payments.answers.eligible_itt_subject.#{sub}") }
        .sort
        .to_sentence(last_word_connector: " or ")
        .downcase
    end

    private

    # TODO: something like this could move elsewhere
    def current_policy_year(current_claim)
      non_nil_policy_year_values = current_claim.policies.collect { |policy| PolicyConfiguration.for(policy).current_academic_year }.compact.to_set

      if non_nil_policy_year_values.one?
        non_nil_policy_year_values.first
      elsif non_nil_policy_year_values.many?
        raise "Have more than one policy year in the same journey"
      else
        raise "Have no policy year for the journey"
      end
    end

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
