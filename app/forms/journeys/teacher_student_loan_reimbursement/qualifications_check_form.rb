module Journeys
  module TeacherStudentLoanReimbursement
    class QualificationsCheckForm < Form
      def save
        true
      end

      def redirect_to_next_slug?
        completed?
      end

      def completed?
        journey_session.answers.trs_data_fetched_at.present?
      end

      def auto_refresh
        3
      end
    end
  end
end
