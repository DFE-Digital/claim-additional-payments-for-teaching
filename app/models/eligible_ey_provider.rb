class EligibleEyProvider < ApplicationRecord
  attribute :academic_year, AcademicYear::Type.new

  belongs_to :local_authority

  def local_authority_code
    local_authority.try :code
  end

  def self.csv_for_academic_year(academic_year)
    csv_columns = {
      "Nursery Name" => :nursery_name,
      "EYURN / Ofsted URN" => :urn,
      "LA Code" => :local_authority_code,
      "Nursery Address" => :nursery_address,
      "Primary Key Contact Email Address" => :primary_key_contact_email_address,
      "Secondary Contact Email Address (Optional)" => :secondary_contact_email_address
    }

    CSV.generate(headers: true) do |csv|
      csv << csv_columns.keys

      where(academic_year:).each do |row|
        csv << csv_columns.values.map { |attr| row.send(attr) }
      end
    end
  end
end
