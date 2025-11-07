module Policies
  module EarlyYearsPayments
    class EligibleEyProvider < ApplicationRecord
      belongs_to :local_authority
      belongs_to :file_upload

      default_scope { where(file_upload: FileUpload.latest_version_for(EligibleEyProvider)) }

      def local_authority_code
        local_authority.try :code
      end

      def self.csv
        csv_columns = {
          "Nursery Name" => :nursery_name,
          "EYURN / Ofsted URN" => :urn,
          "LA Code" => :local_authority_code,
          "Nursery Address" => :nursery_address,
          "Primary Key Contact Email Address" => :primary_key_contact_email_address,
          "Secondary Contact Email Address (Optional)" => :secondary_contact_email_address,
          "Maximum Number Of Claims" => :max_claims
        }

        CSV.generate(headers: true) do |csv|
          csv << csv_columns.keys

          all.includes(:local_authority).each do |row|
            csv << csv_columns.values.map { |attr| row.send(attr) }
          end
        end
      end

      def self.eligible_email?(email_address)
        for_email(email_address).exists?
      end

      def self.for_email(email_address)
        return none unless email_address.present?

        where(primary_key_contact_email_address: email_address).or(
          where(secondary_contact_email_address: email_address)
        )
      end

      def claims
        claim_ids = Policies::EarlyYearsPayments::Eligibility
          .joins(:claim)
          .where(nursery_urn: urn)
          .select("claims.id")

        Claim.where(id: claim_ids)
      end

      def email_addresses
        [
          primary_key_contact_email_address,
          secondary_contact_email_address
        ].compact_blank
      end
    end
  end
end
