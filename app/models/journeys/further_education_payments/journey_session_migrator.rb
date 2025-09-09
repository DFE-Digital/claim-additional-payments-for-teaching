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
        to.save!
      end
    end
  end
end
