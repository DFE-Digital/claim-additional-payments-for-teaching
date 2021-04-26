require "csv"

module AutomatedChecks
  # Parses a report from DQT containing qualification data on claimants.
  # Sets a public errors array if either the file or expected columns are
  # missing or if the CSV is malformed.
  #
  # file - Must be a type of File class that responds to `#to_io`, typically
  #        will be an UploadedFile
  class DqtReportCsv
    attr_reader :rows, :errors

    EXPECTED_HEADERS = [
      "dfeta text1",
      "dfeta text2",
      "dfeta trn",
      "dfeta qtsdate",
      "fullname",
      "birthdate",
      "dfeta ninumber",
      "HESubject1Value",
      "HESubject2Value",
      "HESubject3Value",
      "ITTSub1Value",
      "ITTSub2Value",
      "ITTSub3Value"
    ].freeze

    def initialize(file)
      @errors = []
      @rows = parse_csv(file)
      check_headers
    end

    private

    def check_headers
      if rows
        missing_headers = EXPECTED_HEADERS - rows.headers
        errors.append("The selected file is missing some expected columns: #{missing_headers.join(", ")}") if missing_headers.any?
      end
    end

    def parse_csv(file)
      if file.nil?
        errors.append("Select a file")
        nil
      else
        CSV.read(file.to_io, headers: true, encoding: "BOM|UTF-8")
      end
    rescue CSV::MalformedCSVError
      errors.append("The selected file must be a CSV")
      nil
    end
  end
end
