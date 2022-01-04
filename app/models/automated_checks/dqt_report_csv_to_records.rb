module AutomatedChecks
  class DqtReportCsvToRecords
    Row = Struct.new(
      :active_alert?,
      :claim_reference,
      :date_of_birth,
      :degree_codes,
      :first_name,
      :itt_start_date,
      :itt_subject_codes,
      :national_insurance_number,
      :qts_award_date,
      :qualification_name,
      :surname,
      :teacher_reference_number,
      keyword_init: true
    )

    CLAIM_REFERENCE_COLUMN = "dfeta text2".freeze

    def initialize(csv_rows)
      @csv_rows = csv_rows
    end

    def transform
      @csv_rows.group_by { |row| row.fetch(CLAIM_REFERENCE_COLUMN) }.map do |rows|
        grouped_rows = rows[1]

        Row.new(
          active_alert?: nil,
          claim_reference: grouped_rows.first.fetch(CLAIM_REFERENCE_COLUMN),
          date_of_birth: parse_date(grouped_rows.first.fetch("birthdate")),
          degree_codes: collate_fields_from_rows(%w[HESubject1Value HESubject2Value HESubject3Value], grouped_rows),
          first_name: extract_first_name(grouped_rows.first.fetch("fullname")),
          itt_start_date: nil,
          itt_subject_codes: collate_fields_from_rows(%w[ITTSub1Value ITTSub2Value ITTSub3Value], grouped_rows),
          national_insurance_number: grouped_rows.first.fetch("dfeta ninumber"),
          qts_award_date: parse_date(grouped_rows.first.fetch("dfeta qtsdate")),
          qualification_name: nil,
          surname: extract_surname(grouped_rows.first.fetch("fullname")),
          teacher_reference_number: grouped_rows.first.fetch("dfeta trn")
        )
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
