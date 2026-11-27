require "csv"

module EarlyYearsTeachersFinancialIncentivePayments
  class ImportEligibleEytfiProvidersJob < ApplicationJob
    class RowParser
      # Columns that are played back to the public, so must not contain PII
      PUBLIC_HEADERS = [
        "Provider name",
        "Provider address line 1",
        "Provider address line 2",
        "Provider address line 3",
        "Provider town",
        "Postcode"
      ]

      PRIVATE_HEADERS = [
        "Provider URN",
        "Eligible",
        "Max claims",
        "COPD",
        "Registered person name",
        "Telephone number",
        "PAYE reference",
        "Multiple nurseries?"
      ]

      HEADERS = PUBLIC_HEADERS + PRIVATE_HEADERS

      # Employer PAYE references are a 3 digit tax office number, an
      # optional "/", then the employer's reference, eg "120/XX12345" or
      # "120XX12345". The reference is either all digits or contains a
      # letter followed somewhere by a digit. Postcodes never start with a
      # digit, and requiring a digit after the letter rules out house
      # numbers ("1212a") and ordinals ("227th").
      PAYE_REFERENCE_PATTERN = %r{
        (?<![[:alnum:]/])
        \d{3}/?
        (?:\d{5,7}|[[:alnum:]]*[[:alpha:]][[:alnum:]]*\d[[:alnum:]]*)
        (?![[:alnum:]/])
      }x

      # Shortest PAYE reference we've seen in our data set. Shorter values in
      # the PAYE reference column are ignored when checking whether public
      # fields contain the row's own references, to avoid false positives.
      MIN_PAYE_REFERENCE_LENGTH = 5

      include ActiveModel::Validations

      attr_reader :row

      validate :public_fields_do_not_contain_paye_references

      validates "Provider URN",
        presence: true,
        length: {in: 6..8},
        unless: :copd?

      validates "Provider name",
        presence: true

      validates "Provider address line 1",
        presence: true,
        unless: :copd?

      validates "Provider town",
        presence: true

      validates "Postcode",
        presence: true,
        unless: :copd?

      validates "Eligible",
        presence: true,
        inclusion: {in: %w[TRUE FALSE], message: "must be TRUE or FALSE"}

      validates "Max claims",
        numericality: {only_integer: true, greater_than_or_equal_to: 0},
        if: -> { row["Max claims"].present? }

      validates(
        "Multiple nurseries?",
        inclusion: {
          in: %w[TRUE FALSE],
          message: "must be TRUE or FALSE"
        },
        if: -> { row["Registered person name"].present? }
      )

      validates(
        "Multiple nurseries?",
        absence: true,
        unless: -> { row["Registered person name"].present? }
      )

      def initialize(row:)
        @row = row
        @row.each do |header, value|
          @row[header] = nil if value.to_s.downcase.strip == "n/a"
        end
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
            copd: cast_bool(row["COPD"]),
            max_claims: row["Max claims"].presence || 5,
            registered_person_name: row["Registered person name"].presence,
            telephone_number: row["Telephone number"].presence,
            paye_references: row["PAYE reference"].to_s.lines.map(&:strip).reject { |reference| reference.blank? || reference == "n/a" },
            multiple_nurseries: row["Registered person name"].present? ? cast_bool(row["Multiple nurseries?"]) : nil,
            file_upload:
          )
      end

      def read_attribute_for_validation(key)
        row[key]
      end

      private

      def public_fields_do_not_contain_paye_references
        PUBLIC_HEADERS.each do |header|
          next unless contains_paye_reference?(row[header])

          errors.add(
            header,
            "looks like it contains a PAYE reference, PAYE references " \
            "must only be in the PAYE reference column"
          )
        end
      end

      def contains_paye_reference?(value)
        return false if value.blank?

        normalised = normalise_paye_reference(value)

        return true if paye_references.any? { |ref| normalised.include?(ref) }

        value.match?(PAYE_REFERENCE_PATTERN)
      end

      def paye_references
        @paye_references ||= row["PAYE reference"]
          .to_s
          .lines
          .map { |ref| normalise_paye_reference(ref) }
          .reject { |ref| ref.length < MIN_PAYE_REFERENCE_LENGTH }
      end

      def normalise_paye_reference(value)
        value.to_s.upcase.gsub(/[^[:alnum:]]/, "")
      end

      def copd?
        cast_bool(row["COPD"])
      end

      def cast_bool(value)
        return false if value.blank?

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

      headers = CSV.foreach(body_io).first

      if headers&.tally != RowParser::HEADERS.tally
        file_upload.update(
          upload_errors: [
            "Headers must be #{RowParser::HEADERS.join(", ")}"
          ]
        )

        return
      end

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
          upload_errors: errors
        )

        return
      end

      ApplicationRecord.transaction do
        CSV.foreach(body_io, headers: true) do |row|
          parser = RowParser.new(row:)
          provider = parser.to_provider(file_upload:)
          provider.save!
        end

        file_upload.update completed_processing_at: Time.zone.now
      end
    end
  end
end
