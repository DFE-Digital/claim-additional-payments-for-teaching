module EarlyYearsTeachersFinancialIncentivePayments
  class HmrcEmploymentCheckJob < ApplicationJob
    # Enable `eytrp_hmrc_integration` to turn on the new HMRC journey.
    # Hmrc api call is off by default in review environments, turn it on in
    # these environments by enabling
    # `eytrp_perform_hmrc_api_call_in_review_environments`
    def self.enabled?
      return false unless FeatureFlag.enabled?(:eytrp_hmrc_integration)

      if Rails.env.development? || Rails.env.review_app_like?
        FeatureFlag.enabled?(:eytrp_perform_hmrc_api_call_in_review_environments)
      else
        true
      end
    end

    def perform(journey_session)
      return unless self.class.enabled?

      return if journey_session.answers.hmrc_response_received?

      response = fetch_employment_history(journey_session.answers)

      journey_session.answers.update!(
        hmrc_response_status: response.status,
        hmrc_response_body: response.body
      )
    end

    private

    def fetch_employment_history(answers)
      Hmrc::Employments.client.employment_history_for_individual(
        first_name: answers.teacher_auth_verified_first_name,
        last_name: answers.teacher_auth_verified_last_name,
        date_of_birth: answers.teacher_auth_verified_date_of_birth,
        nino: answers.national_insurance_number,
        from_date: Journeys::EarlyYearsTeachersFinancialIncentivePayments::EmploymentCheck.earliest_date_to_check
      )
    rescue Hmrc::ResponseError => e
      Sentry.capture_exception(e)

      e.response
    end
  end
end
