class EligibleFeProvider < ApplicationRecord
  attribute :academic_year, AcademicYear::Type.new

  validates :primary_key_contact_email_address,
    presence: true,
    email_address_format: true,
    length: {maximum: Rails.application.config.email_max_length}

  def self.csv_for_academic_year(academic_year)
    attribute_names = [:ukprn, :max_award_amount, :lower_award_amount, :primary_key_contact_email_address]

    CSV.generate(headers: true) do |csv|
      csv << attribute_names

      where(academic_year:).each do |row|
        csv << attribute_names.map { |attr| row.send(attr) }
      end
    end
  end
end
