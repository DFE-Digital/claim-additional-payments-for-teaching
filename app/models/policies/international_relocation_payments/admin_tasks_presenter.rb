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
          ["Arrival date", eligibility.date_of_entry.to_fs(:govuk_date)]
        ]
      end

      def identity_confirmation
        [
          ["Nationality", eligibility.nationality],
          ["Passport number", eligibility.passport_number]
        ]
      end

      def visa
        [
          ["Visa type", eligibility.visa_type]
        ]
      end

      private

      delegate :eligibility, to: :claim
    end
  end
end
