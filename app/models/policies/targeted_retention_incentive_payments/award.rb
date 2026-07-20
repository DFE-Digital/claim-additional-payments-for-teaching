require "csv"

module Policies
  module TargetedRetentionIncentivePayments
    class Award < ApplicationRecord
      self.table_name = "targeted_retention_incentive_payments_awards"

      belongs_to :school, foreign_key: :school_urn, primary_key: :urn, inverse_of: :targeted_retention_incentive_payments_awards, optional: true
      belongs_to :file_upload

      scope :by_academic_year, ->(academic_year) {
        where(file_upload: FileUpload.latest_version_for(Award, academic_year))
      }

      validates :academic_year, presence: true
      validates :school_urn, presence: true, numericality: true
      validates :award_amount, presence: true
      validates :award_amount, numericality: {greater_than: 0}

      def self.csv_for_academic_year(academic_year)
        attribute_names = [:school_urn, :award_amount]

        CSV.generate(headers: true) do |csv|
          csv << attribute_names

          by_academic_year(academic_year).each do |row|
            csv << attribute_names.map { |attr| row.send(attr) }
          end
        end
      end

      def self.last_updated_at(academic_year)
        FileUpload
          .latest_version_for(Award, academic_year)
          .first
          &.completed_processing_at
      end

      def self.distinct_academic_years
        select(:academic_year).distinct.order(academic_year: :desc).map(&:academic_year)
      end
    end
  end
end
