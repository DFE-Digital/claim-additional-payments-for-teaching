module Policies
  module StudentLoans
    module PresenterMethods
      def qts_award_year_answer(ineligible_qts_award_year, academic_year)
        if ineligible_qts_award_year
          I18n.t("student_loans.answers.qts_award_years.before_cut_off_date")
        else
          first_eligible_year = Policies::StudentLoans.first_eligible_qts_award_year(academic_year).to_s(:long)
          I18n.t("student_loans.answers.qts_award_years.on_or_after_cut_off_date", year: first_eligible_year)
        end
      end

      def subject_list(subjects)
        connector = " and "
        translated_subjects = subjects.map { |subject| I18n.t("student_loans.forms.subjects_taught.answers.#{subject}") }
        translated_subjects.sort.to_sentence(
          last_word_connector: connector,
          two_words_connector: connector
        )
      end
    end
  end
end
