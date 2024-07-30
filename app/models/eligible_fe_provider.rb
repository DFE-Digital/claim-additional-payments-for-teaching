class EligibleFeProvider < ApplicationRecord
  attribute :academic_year, AcademicYear::Type.new

  def self.csv_for_academic_year(academic_year)
    attribute_names = [:ukprn, :max_award_amount, :lower_award_amount]

    CSV.generate(headers: true) do |csv|
      csv << attribute_names

      where(academic_year:).each do |row|
        csv << attribute_names.map { |attr| row.send(attr) }
      end
    end
  end
end