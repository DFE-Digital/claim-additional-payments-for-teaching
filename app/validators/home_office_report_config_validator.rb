# Example config
# config:
#    {
#      worksheet_name: "Data",
#      header_mapping: {
#        "ID (Mandatory)"               => %w[urn],
#        "Full Name/ Organisation Name" => %w[applicants.given_name applicants.middle_name applicants.family_name],
#        "DOB"                          => %w[applicants.date_of_birth],
#        "Nationality"                  => %w[applicants.nationality],
#        "Passport Number"              => %w[applicants.passport_number],
#      }
#    }
#

class HomeOfficeReportConfigValidator
  def initialize(record)
    @record = record
  end

  def validate
    return if record.report_class != Reports::HomeOfficeExcel.name

    validate_workbook
    validate_config_worksheet_name
    validate_worksheet
    validate_config_header_mappings
  end

private

  attr_reader :record, :workbook

  def validate_workbook
    @workbook = ::RubyXL::Parser.parse_buffer(record.file.dup)
  rescue StandardError
    record.errors.add(:file, :ho_invalid)
  end

  def validate_worksheet
    return if workbook.blank?

    record.errors.add(:config, :ho_invalid_worksheet_name) if workbook[record.config.fetch(Reports::HomeOfficeExcel::WORKSHEET_NAME_KEY, nil)].blank?
  end

  def validate_config_worksheet_name
    record.errors.add(:config, :ho_missing_worksheet_name) if record.config.fetch(Reports::HomeOfficeExcel::WORKSHEET_NAME_KEY, nil).blank?
  end

  def validate_config_header_mappings
    record.errors.add(:config, :ho_missing_header_mappings) if record.config.fetch(Reports::HomeOfficeExcel::HEADER_MAPPINGS_KEY, nil).blank?
  end
end
