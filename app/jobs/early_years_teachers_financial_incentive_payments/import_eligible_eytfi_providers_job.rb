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

      private

      def validate_eligible_input
        return if ["TRUE", "FALSE"].include?(row["Eligible"])

        errors.add(:eligible, "must be TRUE or FALSE")
      end
    end

    def perform(file_upload)
      invalid = false
      body_io = StringIO.new(file_upload.body)

      CSV.foreach(body_io, headers: true).with_index do |row, index|
        parser = RowParser.new(row:)

        if parser.invalid?
          invalid = true
        end
      end

      if invalid
        file_upload.update completed_processing_at: Time.zone.now
        return
      end

      CSV.foreach(body_io, headers: true) do |row|
        provider = Policies::
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

        provider.save!
      end

      file_upload.update completed_processing_at: Time.zone.now
    end

    private

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
end
