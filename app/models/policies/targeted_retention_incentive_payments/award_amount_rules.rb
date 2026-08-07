# frozen_string_literal: true

module Policies
  module TargetedRetentionIncentivePayments
    class AwardAmountRules
      include ActiveSupport::NumberHelper

      def initialize(record)
        @record = record
      end

      def validate(context: nil)
        validate_award_amount_in_range if amendment?(context)
      end

      private

      attr_reader :record

      def amendment?(context)
        Array(context).include?(:amendment)
      end

      def validate_award_amount_in_range
        return if record.award_amount&.between?(1, max_award_amount)

        record.errors.add(
          :award_amount,
          "Enter a positive amount up to #{number_to_currency(max_award_amount)} (inclusive)"
        )
      end

      def max_award_amount
        @max_award_amount ||= Award.by_academic_year(academic_year).maximum(:award_amount)
      end

      # NOTE: this reads the current academic year rather than the year of the
      # claim being amended, which is wrong for a claim from an earlier year.
      # Preserved as-is from the eligibility validation this was extracted from;
      # it becomes record.academic_year once award_amount lives on Claim.
      def academic_year
        TargetedRetentionIncentivePayments.current_academic_year
      end
    end
  end
end
