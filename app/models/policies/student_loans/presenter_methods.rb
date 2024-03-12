module Policies
  module StudentLoans
    module PresenterMethods
      def qts_award_year_answer(eligibility)
        if eligibility.ineligible_qts_award_year?
          I18n.t("student_loans.answers.qts_award_years.before_cut_off_date")
        else
          first_eligible_year = StudentLoans.first_eligible_qts_award_year(eligibility.claim.academic_year).to_s(:long)
          I18n.t("student_loans.answers.qts_award_years.on_or_after_cut_off_date", year: first_eligible_year)
        end
      end

      def subject_list(subjects)
        connector = " and "
        translated_subjects = subjects.map { |subject| I18n.t("student_loans.questions.eligible_subjects.#{subject}") }
        translated_subjects.sort.to_sentence(
          last_word_connector: connector,
          two_words_connector: connector
        )
      end
    end
  end
end
