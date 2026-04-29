require "csv"

module EarlyYearsTeachersFinancialIncentivePayments
  class ImportEligibleEytfiProvidersJob < ApplicationJob
    class RowParser
      include ActiveModel::Validations

      attr_reader :row

      validate :validate_eligible_input

      def initialize(row:)
        @row = row
      end

      def to_provider(file_upload:)
        Policies::
          EarlyYearsTeachersFinancialIncentivePayments::
          EligibleEytfiProvider.new(
            urn: row["Provider URN"],
            name: row["Provider name"],
            address_line_1: row["Provider address line 1"],
            address_line_2: row["Provider address line 2"],
            address_line_3: row["Provider address line 3"],
            town: row["Provider town"],
            postcode: row["Postcode"],
            eligible: cast_bool(row["Eligible"]),
            file_upload:
          )
      end

      private

      def validate_eligible_input
        return if ["TRUE", "FALSE"].include?(row["Eligible"])

        errors.add(:eligible, "must be TRUE or FALSE")
      end

      def cast_bool(value)
        case value
        when "TRUE"
          true
        when "FALSE"
          false
        else
          raise "#{value} could not be cast to a boolean"
        end
      end
    end

    def perform(file_upload)
      invalid = false
      body_io = StringIO.new(file_upload.body)
      errors = []

      CSV.foreach(body_io, headers: true).with_index do |row, index|
        row_counter = index + 2
        parser = RowParser.new(row:)

        if parser.invalid?
          invalid = true

          parser.errors.full_messages.each do |message|
            errors << "Row #{row_counter}: #{message}"
          end
        end
      end

      if invalid
        file_upload.update(
          upload_errors: errors,
          completed_processing_at: Time.zone.now
        )

        return
      end

      CSV.foreach(body_io, headers: true) do |row|
        parser = RowParser.new(row:)
        provider = parser.to_provider(file_upload:)
        provider.save!
      end

      file_upload.update completed_processing_at: Time.zone.now
    end
  end
end
