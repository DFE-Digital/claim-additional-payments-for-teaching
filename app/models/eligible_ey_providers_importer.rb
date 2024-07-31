class EligibleEyProvidersImporter < CsvImporter::Base
  import_options(
    target_data_model: EligibleEyProvider,
    transform_rows_with: :row_to_hash,
    mandatory_headers: [
      "Nursery Name",
      "EYURN / Ofsted URN",
      "LA Code",
      "Nursery Address",
      "Primary Key Contact Email Address",
      "Secondary Contact Email Address (Optional)"
    ]
  )

  attr_reader :academic_year

  def initialize(file, academic_year)
    super(file)

    @academic_year = academic_year
  end

  def results_message
    "Replaced #{deleted_row_count} existing providers with #{rows.count} new providers"
  end

  private

  def delete_all_scope
    target_data_model.where(academic_year:)
  end

  def row_to_hash(row)
    {
      nursery_name: row.fetch("Nursery Name"),
      urn: row.fetch("EYURN / Ofsted URN"),
      local_authority_id: LocalAuthority.find_by(code: row.fetch("LA Code")).try(:id),
      nursery_address: row.fetch("Nursery Address"),
      primary_key_contact_email_address: row.fetch("Primary Key Contact Email Address"),
      secondary_contact_email_address: row.fetch("Secondary Contact Email Address (Optional)"),
      academic_year:
    }
  end
end
