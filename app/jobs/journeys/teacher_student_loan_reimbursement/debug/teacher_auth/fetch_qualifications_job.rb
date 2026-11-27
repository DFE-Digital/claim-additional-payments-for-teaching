module Journeys
  module TeacherStudentLoanReimbursement
    module Debug
      module TeacherAuth
        class FetchQualificationsJob < ApplicationJob
          JOB_SLEEP_SECONDS = 5

          def perform(journey_session)
            # Sleep to simulate fetching DQT teacher status from TRS
            # In debug we set this in the controller from the debug form's value
            sleep JOB_SLEEP_SECONDS

            journey_session.answers.update!(trs_data_fetched_at: Time.zone.now)
          end
        end
      end
    end
  end
end
