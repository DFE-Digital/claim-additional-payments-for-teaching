require "csv"

module CsvImporter
  class Base
    include CsvImporter::Config

    attr_reader :errors, :rows, :deleted_row_count, :skipped_row_count

    def initialize(file)
      @errors = []
      @rows = parse_csv_file(file)
      @deleted_row_count = 0
      @skipped_row_count = 0

      check_headers if rows && with_headers?
    end

    def run
      @deleted_row_count = delete_all_scope.delete_all unless append_only

      rows.each_slice(batch_size).with_index(1) do |batch_rows, i|
        Rails.logger.info "Processing #{target_data_model.to_s.titleize} batch #{i}"

        record_hashes = batch_rows.map do |row|
          if empty_row?(row) || valid_skip_row_conditions?(row)
            @skipped_row_count += 1
            next
          end

          convert_row_to_hash(row)
        end.compact

        target_data_model.insert_all(record_hashes) unless record_hashes.empty?
      end

      sync_analytics
    end

    def rows_with_data_count
      rows.count - skipped_row_count
    end

    private

    def sync_analytics
      AnalyticsImporter.import(target_data_model)
    end

    def empty_row?(row)
      case row
      when Array
        row.all? { |cell| cell.blank? }
      else
        row.all? { |_, v| v.blank? }
      end
    end

    def delete_all_scope
      target_data_model
    end

    def with_headers?
      parse_headers && mandatory_headers&.is_a?(Array) && mandatory_headers.any?
    end

    def check_headers
      missing_headers = mandatory_headers - rows.headers

      if missing_headers.any?
        errors.append("The selected file is missing some expected columns: #{missing_headers.join(", ")}")
      end
    end

    def parse_csv_file(file)
      if file.nil?
        errors.append("Select a file")
        nil
      else
        string = File.open(file.path, "r", encoding: "BOM|UTF-8").read.scrub
        CSV.parse(string, headers: parse_headers)
      end
    rescue CSV::MalformedCSVError
      errors.append("The selected file must be a CSV")
      nil
    end

    def valid_skip_row_conditions?(row)
      return false unless skip_row_if_method || skip_row_if_lambda
      return method(skip_row_if_method).call(row) if skip_row_if_method

      skip_row_if_lambda&.call(row)
    end

    def convert_row_to_hash(row)
      return method(transform_rows_with_method).call(row) if transform_rows_with_method

      transform_rows_with_lambda&.call(row)
    end
  end
end
