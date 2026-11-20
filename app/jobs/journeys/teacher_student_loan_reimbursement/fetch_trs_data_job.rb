module Journeys
  module TeacherStudentLoanReimbursement
    class FetchTrsDataJob < ApplicationJob
      def perform(journey_session)
        answers = journey_session.answers

        return if answers.trs_data_fetched_at.present?

        trs_data = fetch_trs_data(answers.teacher_auth_teacher_reference_number)

        national_insurance_number = Dqt::Teacher.new(
          trs_data
        ).national_insurance_number.presence

        answers.update!(
          dqt_teacher_status: trs_data,
          national_insurance_number: national_insurance_number,
          teacher_auth_national_insurance_number: national_insurance_number,
          trs_data_fetched_at: Time.current
        )
      end

      private

      def fetch_trs_data(trn)
        Dqt::Client.new.teacher.find_raw(trn, include: "alerts") || {}
      rescue Dqt::Error, Faraday::Error => error
        Sentry.capture_exception(error)
        {}
      end
    end
  end
end
