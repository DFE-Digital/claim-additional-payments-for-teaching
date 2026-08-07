# frozen_string_literal: true

module Policies
  module StudentLoans
    class AwardAmountRules
      MAX_AWARD_AMOUNT = 99_999
      MAX_AMENDED_AWARD_AMOUNT = 5_000

      def initialize(record)
        @record = record
      end

      def validate(context: nil)
        monetary_amount_validator.validate(record)

        if amendment?(context) && record.award_amount_changed?
          amended_award_range_validator.validate(record)
        end
      end

      private

      attr_reader :record

      def amendment?(context)
        Array(context).include?(:amendment)
      end

      def monetary_amount_validator
        ActiveModel::Validations::NumericalityValidator.new(
          attributes: [:award_amount],
          message: "Enter a valid monetary amount",
          allow_nil: true,
          greater_than_or_equal_to: 0,
          less_than_or_equal_to: MAX_AWARD_AMOUNT
        )
      end

      def amended_award_range_validator
        ::AwardRangeValidator.new(
          attributes: [:award_amount],
          max: MAX_AMENDED_AWARD_AMOUNT
        )
      end
    end
  end
end
