module Tasks
  module EarlyYearsTeachersFinancialIncentivePayments
    class EmploymentJob < ApplicationJob
      MAX_ATTEMPTS = 5

      def perform(claim)
        eligibility = claim.eligibility

        return if claim.tasks.employment.exists?

        if hmrc_check_enabled?
          eligibility.increment!(:hmrc_employment_check_attempts)

          # How far back we check employment history
          from_date = 2.months.ago.to_date

          to_date = Date.current
          response = fetch_employment_history!(claim:, from_date:)

          if retry_request?(response, eligibility.hmrc_employment_check_attempts)
            delay = eligibility.hmrc_employment_check_attempts.minutes

            self.class.set(wait: delay).perform_later(claim)

            return
          end

          eligibility.update!(
            hmrc_response_status: response.status,
            hmrc_response_body: response.body,
            employment_check_date_range_start: from_date,
            employment_check_date_range_end: to_date
          )
        end

        task = claim.tasks.employment.new

        employment_check = Journeys::EarlyYearsTeachersFinancialIncentivePayments::EmploymentCheck.new(
          setting: eligibility.nursery,
          hmrc_response_status: eligibility.hmrc_response_status,
          hmrc_response_body: eligibility.hmrc_response_body
        )

        result = employment_check.result

        task.data = {
          check: result.check,
          passed: result.passed?,
          failure_reason: result.failure_reason
        }

        if result.passed?
          task.passed = true
          task.manual = false
        else
          task.passed = nil
          task.manual = true
          task.reason = "incomplete" # set this so the task presenter shows "Incomplete"
        end

        task.save!(context: :claim_verifier)

        task
      end

      private

      def hmrc_check_enabled?
        FeatureFlag.enabled?(:eytrp_hmrc_integration)
      end

      def retry_request?(response, attempts)
        return false if response.status == 200
        # If we get a 404 error it means the claimant wasn't found on HMRC with
        # the details provided, retrying wont help.
        return false if response.status == 404

        attempts < MAX_ATTEMPTS
      end

      def fetch_employment_history!(claim:, from_date:)
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
        Sentry.capture_exception(
          e,
          contexts: {"Claim" => {reference: claim.reference}}
        )

        e.response
      end
    end
  end
end
