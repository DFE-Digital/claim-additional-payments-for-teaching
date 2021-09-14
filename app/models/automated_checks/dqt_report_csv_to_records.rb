module AutomatedChecks
  class DqtReportCsvToRecords
    CLAIM_REFERENCE_COLUMN = "dfeta text2".freeze

    def initialize(csv_rows)
      @csv_rows = csv_rows
    end

    def transform
      @csv_rows.group_by { |row| row.fetch(CLAIM_REFERENCE_COLUMN) }.map do |rows|
        grouped_rows = rows[1]
        {
          claim_reference: grouped_rows.first.fetch(CLAIM_REFERENCE_COLUMN),
          teacher_reference_number: grouped_rows.first.fetch("dfeta trn"),
          qts_date: parse_date(grouped_rows.first.fetch("dfeta qtsdate")),
          first_name: extract_first_name(grouped_rows.first.fetch("fullname")),
          surname: extract_surname(grouped_rows.first.fetch("fullname")),
          date_of_birth: parse_date(grouped_rows.first.fetch("birthdate")),
          national_insurance_number: grouped_rows.first.fetch("dfeta ninumber"),
          degree_codes: collate_fields_from_rows(%w[HESubject1Value HESubject2Value HESubject3Value], grouped_rows),
          itt_subject_codes: collate_fields_from_rows(%w[ITTSub1Value ITTSub2Value ITTSub3Value], grouped_rows),
          itt_date: nil,
          qualification_name: nil
        }
      end
    end

    private

    def collate_fields_from_rows(fields, rows)
      rows.map { |c| c.to_h.slice(*fields).values }.flatten.compact.uniq
    end

    def parse_date(date)
      Date.parse(date)
    rescue
      nil
    end

    def extract_first_name(fullname)
      (fullname || "").split(" ").first
    end

    def extract_surname(fullname)
      (fullname || "").split(" ").last
    end
  end
end
