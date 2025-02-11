require "csv"

module Policies
  module LevellingUpPremiumPayments
    class AwardCsvImporter
      include ActiveModel::Model
      include ActiveModel::Attributes

      attribute :academic_year, :string
      attr_accessor :csv_data, :admin_user

      validates :academic_year, format: {with: AcademicYear::ACADEMIC_YEAR_REGEXP}, presence: true
      validates :csv_data, presence: {message: "Choose a CSV file to upload"}
      validate :csv_can_be_parsed, if: -> { csv_data.present? }
      validate :validate_csv_headers, if: -> { csv_data.present? }
      validate :csv_rows_are_valid, if: -> { csv_data.present? && csv_headers_present? }

      def initialize(attributes = {})
        super
        @records = []
      end

      def process
        return false unless valid?
        commit!
        file_upload.completed_processing!
      end

      private

      def file_upload
        @file_upload ||= FileUpload.new(
          uploaded_by: admin_user,
          body: File.read(csv_data),
          target_data_model: Policies::LevellingUpPremiumPayments::Award.to_s,
          academic_year: academic_year.to_s
        )
      end

      def commit!
        LevellingUpPremiumPayments::Award.transaction do
          @records.each(&:save!)
        end
      end

      def csv_can_be_parsed
        parse_csv
      rescue
        errors.add(:csv_data, :invalid, message: "is not a valid CSV file")
      end

      def parse_csv
        @parsed_csv ||= CSV.read(csv_data.to_io, headers: true, encoding: "BOM|UTF-8")
      end

      def csv_headers_present?
        parse_csv.headers == ["school_urn", "award_amount"]
      end

      def validate_csv_headers
        errors.add(:csv_data, :invalid, message: "Invalid headers in CSV file. Required headers are school_urn and award_amount") unless csv_headers_present?
      end

      def csv_rows_are_valid
        file_upload.save!

        parse_csv.each.with_index(1) do |row, line|
          next if /\A[0.]+\z/.match?(row["award_amount"])

          record = LevellingUpPremiumPayments::Award.new(row.to_h.merge(academic_year: academic_year, file_upload_id: file_upload.id))
          @records << record

          unless record.valid?
            record.errors.full_messages.each do |message|
              errors.add(:csv_data, :invalid, message: "Line #{line}: #{message}")
            end
          end
        end
      end
    end
  end
end
