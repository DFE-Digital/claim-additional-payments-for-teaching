# TODO update the forms to allow switching to a HMRC by pass and update t auth
# page to allow setting HMRC stuff
module EarlyYearsTeachersFinancialIncentivePayments
  class HmrcEmploymentCheckJob < ApplicationJob
    def perform(journey_session)
      return if journey_session.answers.hmrc_api_job_completed?

      employment_history = Hmrc::EmploymentHistory.new(
        full_name: journey_session.answers.teacher_auth_verified_name,
        date_of_birth: journey_session.answers.teacher_auth_verified_date_of_birth,
        national_insurance_number: journey_session.answers.national_insurance_number
      )

      employment_history.request!

      if !employment_history.request_successful?
        journey_session.answers.update!(
          hmrc_employment_check_status: "failed",
          hmrc_employment_history: nil,
          hmrc_api_job_completed: true
        )

        return
      end

      journey_session.answers.assign_attributes(
        hmrc_employment_history: employment_history.employments,
        hmrc_api_job_completed: true
      )

      employment_check = Journeys::EarlyYearsTeachersFinancialIncentivePayments::EmploymentCheck.new(
        setting: journey_session.answers.nursery,
        employments: journey_session.answers.hmrc_employment_history
      )

      if employment_check.passed?
        journey_session.answers.assign_attributes(
          hmrc_employment_check_status: "success"
        )
      else
        journey_session.answers.assign_attributes(
          hmrc_employment_check_status: "failed"
        )
      end

      journey_session.save!
    end
  end
end
