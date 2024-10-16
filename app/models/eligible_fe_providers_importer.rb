class EligibleFeProvidersImporter < CsvImporter::Base
  import_options(
    target_data_model: EligibleFeProvider,
    transform_rows_with: :row_to_hash,
    mandatory_headers: %w[
      ukprn
      max_award_amount
      lower_award_amount
      primary_key_contact_email_address
    ]
  )

  attr_reader :academic_year

  def initialize(file, academic_year)
    super(file)

    @academic_year = academic_year
  end

  def results_message
    "Replaced #{deleted_row_count} existing providers with #{rows_with_data_count} new providers"
  end

  private

  def delete_all_scope
    target_data_model.where(academic_year:)
  end

  def row_to_hash(row)
    {
      ukprn: row.fetch("ukprn"),
      max_award_amount: row.fetch("max_award_amount"),
      lower_award_amount: row.fetch("lower_award_amount"),
      primary_key_contact_email_address: row.fetch("primary_key_contact_email_address"),
      academic_year:
    }
  end
end
