module EarlyYearsTeachersFinancialIncentivePayments
  class HmrcEmploymentCheckJob < ApplicationJob
    def self.enabled?
      FeatureFlag.enabled?(:eytrp_hmrc_integration)
    end

    def perform(claim)
      return unless self.class.enabled?

      eligibility = claim.eligibility
      return if eligibility.hmrc_response_status.present?

      from_date = Journeys::EarlyYearsTeachersFinancialIncentivePayments::
        EmploymentCheck.earliest_date_to_check
      to_date = Date.current
      response = fetch_employment_history(claim: claim, from_date: from_date)

      eligibility.update!(
        hmrc_response_status: response.status,
        hmrc_response_body: response.body,
        employment_check_date_range_start: from_date,
        employment_check_date_range_end: to_date
      )
    end

    private

    def fetch_employment_history(claim:, from_date:)
      # HMRC identity matching must use Teacher Auth verified details
      verified_name_parts = claim.eligibility.teacher_auth_verified_name.split

      Hmrc::Employments.client.employment_history_for_individual(
        first_name: verified_name_parts.first,
        last_name: verified_name_parts.last,
        date_of_birth: claim.eligibility.teacher_auth_verified_date_of_birth,
        nino: claim.national_insurance_number,
        from_date: from_date
      )
    rescue Hmrc::ResponseError => e
      Sentry.capture_exception(e)

      e.response
    end
  end
end
