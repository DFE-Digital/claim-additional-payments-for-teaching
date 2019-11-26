module StudentLoans
  module PresenterMethods
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
