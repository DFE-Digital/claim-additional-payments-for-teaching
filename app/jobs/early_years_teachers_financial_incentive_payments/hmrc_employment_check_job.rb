module EarlyYearsTeachersFinancialIncentivePayments
  class HmrcEmploymentCheckJob < ApplicationJob
    def self.enabled?
      FeatureFlag.enabled?(:eytrp_hmrc_integration)
    end

    def perform(claim)
      return unless self.class.enabled?

      eligibility = claim.eligibility
      return if eligibility.hmrc_response_status.present?

      response = fetch_employment_history(claim)

      eligibility.update!(
        hmrc_response_status: response.status,
        hmrc_response_body: response.body
      )
    end

    private

    def fetch_employment_history(claim)
      # HMRC identity matching must use Teacher Auth verified details
      verified_name_parts = claim.eligibility.teacher_auth_verified_name.split

      Hmrc::Employments.client.employment_history_for_individual(
        first_name: verified_name_parts.first,
        last_name: verified_name_parts.last,
        date_of_birth: claim.eligibility.teacher_auth_verified_date_of_birth,
        nino: claim.national_insurance_number,
        from_date: Journeys::EarlyYearsTeachersFinancialIncentivePayments::EmploymentCheck.earliest_date_to_check
      )
    rescue Hmrc::ResponseError => e
      Sentry.capture_exception(e)

      e.response
    end
  end
end
