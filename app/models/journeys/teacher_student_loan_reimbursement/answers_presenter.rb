module Journeys
  module TeacherStudentLoanReimbursement
    class AnswersPresenter < BaseAnswersPresenter
      include StudentLoansHelper
      include Policies::StudentLoans::PresenterMethods
      include ActiveSupport::NumberHelper

      # Formats the eligibility as a list of questions and answers, each
      # accompanied by a slug for changing the answer. Suitable for playback to
      # the claimant for them to review on the check-your-answers page.
      #
      # Returns an array. Each element of this an array is an array of three
      # elements:
      # [0]: question text;
      # [1]: answer text;
      # [2]: slug for changing the answer.
      def eligibility_answers
        [].tap do |a|
          a << qts_award_year unless eligibility.claim.qualifications_details_check
          a << claim_school
          a << current_school
          a << subjects_taught
          a << leadership_position
          a << mostly_performed_leadership_duties if answers.had_leadership_position?
        end
      end

      private

      def qts_award_year
        [
          t("student_loans.forms.qts_year.questions.qts_award_year"),
          qts_award_year_answer(eligibility),
          "qts-year"
        ]
      end

      def claim_school
        [
          claim_school_question,
          answers.claim_school_name,
          (eligibility.claim_school_somewhere_else == false) ? "select-claim-school" : "claim-school"
        ]
      end

      def current_school
        [
          t("student_loans.forms.still_teaching.questions.tps_school"),
          eligibility.current_school_name,
          "still-teaching"
        ]
      end

      def subjects_taught
        [
          subjects_taught_question(school_name: answers.claim_school_name),
          subject_list(answers.subjects_taught),
          "subjects-taught"
        ]
      end

      def leadership_position
        [
          leadership_position_question,
          (answers.had_leadership_position? ? "Yes" : "No"),
          "leadership-position"
        ]
      end

      def mostly_performed_leadership_duties
        [
          mostly_performed_leadership_duties_question,
          (answers.mostly_performed_leadership_duties? ? "Yes" : "No"),
          "mostly-performed-leadership-duties"
        ]
      end
    end
  end
end
