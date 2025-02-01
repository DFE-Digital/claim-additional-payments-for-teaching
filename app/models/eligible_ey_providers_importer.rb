class EligibleEyProvidersImporter < CsvImporter::Base
  import_options(
    target_data_model: EligibleEyProvider,
    append_only: true, # Note: the table is never purged
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

  attr_reader :file_upload_id

  def run(file_upload_id)
    @file_upload_id = file_upload_id

    super()
  end

  def results_message
    "#{rows.count} providers imported"
  end

  private

  def row_to_hash(row)
    {
      nursery_name: row.fetch("Nursery Name"),
      urn: row.fetch("EYURN / Ofsted URN"),
      local_authority_id: LocalAuthority.find_by(code: row.fetch("LA Code")).try(:id),
      nursery_address: row.fetch("Nursery Address"),
      primary_key_contact_email_address: row.fetch("Primary Key Contact Email Address"),
      secondary_contact_email_address: row.fetch("Secondary Contact Email Address (Optional)"),
      file_upload_id:
    }
  end
end
