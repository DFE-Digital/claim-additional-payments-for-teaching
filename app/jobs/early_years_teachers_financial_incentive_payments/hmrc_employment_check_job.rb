module EarlyYearsTeachersFinancialIncentivePayments
  class HmrcEmploymentCheckJob < ApplicationJob
    JOB_TIMEOUT_SECONDS = 5

    def perform(journey_session)
      return if journey_session.answers.hmrc_api_job_completed?

      sleep JOB_TIMEOUT_SECONDS.seconds

      journey_session.answers.update!(
        hmrc_employment_check_status: "failed",
        hmrc_api_job_completed: true
      )
    end
  end
end
