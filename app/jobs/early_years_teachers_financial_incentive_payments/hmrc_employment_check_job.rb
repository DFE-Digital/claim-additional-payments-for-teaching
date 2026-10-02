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

      return if journey_session.answers.hmrc_api_job_completed?

      employment_history = fetch_employment_history(journey_session.answers)

      if employment_history.failed?
        notify_sentry(employment_history) if employment_history.unexpected_format?

        journey_session.answers.update!(
          hmrc_employment_check_passed: false,
          hmrc_employent_api_call_status: "failed",
          hmrc_employment_history: nil,
          hmrc_api_job_completed: true
        )

        return
      end

      journey_session.answers.assign_attributes(
        hmrc_employment_history: employment_history.employments,
        hmrc_api_job_completed: true,
        hmrc_employent_api_call_status: "success"
      )

      employment_check = Journeys::EarlyYearsTeachersFinancialIncentivePayments::EmploymentCheck.new(
        setting: journey_session.answers.nursery,
        employments: journey_session.answers.hmrc_employment_history
      )

      journey_session.answers.assign_attributes(
        hmrc_employment_check_passed: employment_check.passed?
      )

      journey_session.save!
    end

    private

    def fetch_employment_history(answers)
      response = Hmrc::Employments.client.employment_history_for_individual(
        first_name: answers.teacher_auth_verified_first_name,
        last_name: answers.teacher_auth_verified_last_name,
        date_of_birth: answers.teacher_auth_verified_date_of_birth,
        nino: answers.national_insurance_number,
        from_date: Journeys::EarlyYearsTeachersFinancialIncentivePayments::EmploymentCheck.earliest_date_to_check
      )

      return HmrcResponse.failure(:no_match) if response.nil?

      HmrcResponse.new(raw_response: response)
    rescue Hmrc::ResponseError => e
      Sentry.capture_exception(e)

      HmrcResponse.failure(:api_error)
    end

    def notify_sentry(employment_history)
      Sentry.capture_message(
        <<~MSG,
          EarlyYearsTeachersFinancialIncentivePayments::HmrcEmploymentCheckJob
          Unexpected employment history response body from HMRC
          #{employment_history.raw_response.to_json}
        MSG
        level: :error
      )
    end

    class HmrcResponse
      attr_reader :raw_response, :employments, :failure_reason

      def self.failure(reason)
        new(failure_reason: reason)
      end

      def initialize(raw_response: nil, failure_reason: nil)
        @raw_response = raw_response
        @failure_reason = failure_reason
        @unexpected_format = false

        parse_response unless request_failed?
      end

      def failed?
        request_failed? || unexpected_format?
      end

      def unexpected_format?
        @unexpected_format
      end

      private

      def request_failed?
        failure_reason.present?
      end

      def parse_response
        body = JSON.parse(raw_response.body)

        if valid_response?(body)
          @employments = body.fetch("employments")
        else
          @unexpected_format = true
        end
      rescue JSON::ParserError
        @unexpected_format = true
      end

      # Ensure all employments match the expected schema before downstream
      # consumers attempt to use them.
      def valid_response?(body)
        return false unless body.is_a?(Hash) && body["employments"].is_a?(Array)

        body["employments"].all? do |employment|
          employment.is_a?(Hash) &&
            employment["employer"].is_a?(Hash) &&
            employment["employer"]["name"].is_a?(String) &&
            employment["employer"]["name"].present?
        end
      end
    end
  end
end
