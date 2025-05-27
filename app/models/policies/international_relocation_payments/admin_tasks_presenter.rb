module Policies
  module InternationalRelocationPayments
    class AdminTasksPresenter
      include Admin::PresenterMethods

      attr_reader :claim

      def initialize(claim)
        @claim = claim
      end

      def arrival_date
        [
          ["Arrival date", eligibility.date_of_entry.to_fs(:govuk_date)],
          ["Employment start date", eligibility.start_date&.to_fs(:govuk_date)]
        ]
      end

      def employment
        [
          ["Workplace", display_school(eligibility.current_school, include_dfe_number: false)],
          ["Employment contract of at least one year", eligibility.one_year? ? "Yes" : "No"],
          ["Employment start date", eligibility.start_date&.to_fs(:govuk_date)],
          ["Subject employed to teach", eligibility.subject.humanize]
        ]
      end

      def employment_contract
        [
          ["Employment contract at least one year", eligibility.one_year?]
        ]
      end

      def employment_start
        [
          ["Employment start date", eligibility.start_date&.to_fs(:govuk_date)]
        ]
      end

      def identity_confirmation
        [
          ["Nationality", eligibility.nationality],
          ["Passport number", eligibility.passport_number]
        ]
      end

      def subject
        [
          ["Subject employed to teach", eligibility.subject.humanize]
        ]
      end

      def visa
        [
          ["Visa type", eligibility.visa_type]
        ]
      end

      # We don't have a specific teaching hours question so we show the subject
      # to admins
      def teaching_hours
        [
          ["Subject", eligibility.subject.humanize]
        ]
      end

      private

      delegate :eligibility, to: :claim
    end
  end
end
