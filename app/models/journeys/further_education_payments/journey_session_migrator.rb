module Journeys
  module FurtherEducationPayments
    # given an existing journey session
    # transfer details to another journey session
    # this allows users to continue from an existing journey session
    class JourneySessionMigrator < Journeys::EligibilityChecker
      attr_reader :from, :to

      def initialize(from:, to:)
        @from = from
        @to = to
      end

      def call
        to.answers.assign_attributes(from.answers.attributes)

        # handle blanking of answers prior to resuming
        if to.answers.respond_to?(:work_email_access) &&
            to.answers.work_email_access == false
          to.answers.work_email_access = nil
        end

        to.save!
      end
    end
  end
end
