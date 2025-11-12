module Policies
  module EarlyYearsPayments
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
          "Secondary Contact Email Address (Optional)",
          "Maximum Number Of Claims"
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
          nursery_name: row.fetch("Nursery Name").strip,
          urn: row.fetch("EYURN / Ofsted URN").strip,
          local_authority_id: LocalAuthority.find_by(code: row.fetch("LA Code").strip).try(:id),
          nursery_address: row.fetch("Nursery Address").strip,
          primary_key_contact_email_address: row.fetch("Primary Key Contact Email Address").strip,
          secondary_contact_email_address: row.fetch("Secondary Contact Email Address (Optional)").try(:strip),
          max_claims: Integer(row.fetch("Maximum Number Of Claims").strip),
          file_upload_id:
        }
      end
    end
  end
end
