module Claims
  module IttSubjectHelper
    def subjects_to_sentence_for_hint_text(answers)
      all_ecp_subjects = Policies::EarlyCareerPayments.subject_symbols(
        claim_year: answers.policy_year,
        itt_year: answers.itt_academic_year
      )
      all_targeted_retention_incentive_subjects = Policies::TargetedRetentionIncentivePayments.fixed_subject_symbols

      hint_subject_symbols = Set[]

      if answers.nqt_in_academic_year_after_itt
        ecp_eligibility_status = Policies::EarlyCareerPayments::PolicyEligibilityChecker.new(answers: answers).status
        targeted_retention_incentive_eligibility_status = Policies::TargetedRetentionIncentivePayments::PolicyEligibilityChecker.new(answers: answers).status

        potentially_eligible_for_targeted_retention_incentive = targeted_retention_incentive_eligibility_status != :ineligible
        potentially_eligible_for_ecp = ecp_eligibility_status != :ineligible

        hint_subject_symbols.merge(all_ecp_subjects) if potentially_eligible_for_ecp
        hint_subject_symbols.merge(all_targeted_retention_incentive_subjects) if potentially_eligible_for_targeted_retention_incentive

        # When ITT 19/20 and Maths are selected, the ECP eligibility status is "eligible_later",
        # even though we still need to display a list of subjects.
        # In this case we need to selectively replace the entire list of subjects based on whether
        # the other claim (TRI) is ineligible or not.
        if ecp_eligibility_status == :eligible_later
          hint_subject_symbols.replace(potentially_eligible_for_targeted_retention_incentive ? all_targeted_retention_incentive_subjects : all_ecp_subjects)
        end
      else
        hint_subject_symbols.merge(all_targeted_retention_incentive_subjects)
      end

      hint_subject_symbols.map { |sub| t("additional_payments.forms.eligible_itt_subject.answers.#{sub}") }
        .sort
        .to_sentence(last_word_connector: " or ")
        .downcase
    end
  end
end
