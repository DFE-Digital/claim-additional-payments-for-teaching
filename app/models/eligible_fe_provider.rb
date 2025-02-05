class EligibleFeProvider < ApplicationRecord
  attribute :academic_year, AcademicYear::Type.new
  belongs_to :file_upload

  scope :by_academic_year, ->(academic_year) {
    where(file_upload: FileUpload.latest_version_for(EligibleFeProvider, academic_year))
  }

  validates :primary_key_contact_email_address,
    presence: true,
    email_address_format: true,
    length: {maximum: Rails.application.config.email_max_length}

  def self.csv_for_academic_year(academic_year)
    attribute_names = [:ukprn, :max_award_amount, :lower_award_amount, :primary_key_contact_email_address]

    CSV.generate(headers: true) do |csv|
      csv << attribute_names

      by_academic_year(academic_year).each do |row|
        csv << attribute_names.map { |attr| row.send(attr) }
      end
    end
  end
end
