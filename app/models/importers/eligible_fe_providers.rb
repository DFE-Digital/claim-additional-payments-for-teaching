require "csv"

class Importers::EligibleFeProviders
  include ActiveModel::Model

  attr_reader :file, :academic_year

  validate :validate_first_row_headers

  def self.headers
    %w[
      ukprn
      max_award_amount
      lower_award_amount
    ]
  end

  def initialize(file:, academic_year:)
    @file = file
    @academic_year = academic_year
  end

  def call
    return if invalid?

    ApplicationRecord.transaction do
      @added_records = []
      @deleted_records = EligibleFeProvider.where(academic_year:).destroy_all

      rows.each do |row|
        @added_records << EligibleFeProvider.create(row.to_h.merge(academic_year:))
      end
    end
  end

  def results_message
    "Replaced #{@deleted_records.count} existing providers with #{@added_records.count} new providers"
  end

  private

  def first_row
    @first_row ||= CSV.read(file.path)[0]
  end

  def rows
    @rows ||= CSV.read(file.path, headers: true)
  end

  def validate_first_row_headers
    unless first_row == self.class.headers
      errors.add(:file, "Incorrect headers")
    end
  end
end
