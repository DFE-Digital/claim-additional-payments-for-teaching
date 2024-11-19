require "journey_subject_eligibility_checker"

module Claims
  module IttSubjectHelper
    def subjects_to_sentence_for_hint_text(answers)
      all_ecp_subjects = [:chemistry, :foreign_languages, :mathematics, :physics]
      all_lup_subjects = Policies::LevellingUpPremiumPayments.fixed_subject_symbols

      hint_subject_symbols = Set[]

      if answers.nqt_in_academic_year_after_itt
        ecp_eligibility_status = Policies::EarlyCareerPayments::PolicyEligibilityChecker.new(answers: answers).status
        lup_eligibility_status = Policies::LevellingUpPremiumPayments::PolicyEligibilityChecker.new(answers: answers).status

        potentially_eligible_for_lup = lup_eligibility_status != :ineligible
        potentially_eligible_for_ecp = ecp_eligibility_status != :ineligible

        hint_subject_symbols.merge(all_ecp_subjects) if potentially_eligible_for_ecp
        hint_subject_symbols.merge(all_lup_subjects) if potentially_eligible_for_lup

        # When ITT 19/20 and Maths are selected, the ECP eligibility status is "eligible_later",
        # even though we still need to display a list of subjects.
        # In this case we need to selectively replace the entire list of subjects based on whether
        # the other claim (LUP) is ineligible or not.
        if ecp_eligibility_status == :eligible_later
          hint_subject_symbols.replace(potentially_eligible_for_lup ? all_lup_subjects : all_ecp_subjects)
        end
      else
        hint_subject_symbols.merge(all_lup_subjects)
      end

      hint_subject_symbols.map { |sub| t("additional_payments.forms.eligible_itt_subject.answers.#{sub}") }
        .sort
        .to_sentence(last_word_connector: " or ")
        .downcase
    end
  end
end
