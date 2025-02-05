class EligibleFeProvidersImporter < CsvImporter::Base
  import_options(
    target_data_model: EligibleFeProvider,
    append_only: true, # Note: the table is never purged
    transform_rows_with: :row_to_hash,
    mandatory_headers: %w[
      ukprn
      max_award_amount
      lower_award_amount
      primary_key_contact_email_address
    ]
  )

  attr_reader :academic_year, :file_upload_id

  def initialize(file, academic_year)
    super(file)

    @academic_year = academic_year
  end

  def run(file_upload_id)
    @file_upload_id = file_upload_id

    super()
  end

  def results_message
    "#{rows_with_data_count} providers imported for #{academic_year}"
  end

  private

  def row_to_hash(row)
    {
      ukprn: row.fetch("ukprn"),
      max_award_amount: row.fetch("max_award_amount").gsub(/£|,|�/, ""),
      lower_award_amount: row.fetch("lower_award_amount").gsub(/£|,|�/, ""),
      primary_key_contact_email_address: row.fetch("primary_key_contact_email_address"),
      academic_year:,
      file_upload_id:
    }
  end
end
