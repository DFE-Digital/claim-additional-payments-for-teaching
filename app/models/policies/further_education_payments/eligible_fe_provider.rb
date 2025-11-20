module Policies
  module FurtherEducationPayments
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

      def claims
        Claim
          .joins(
            <<~SQL
              INNER JOIN further_education_payments_eligibilities
              ON further_education_payments_eligibilities.id = claims.eligibility_id
            SQL
          )
          .merge(Eligibility.where(school_id: school.id))
      end

      def claims_overdue_verification
        unverified_claims.where(claims: {created_at: ..2.weeks.ago})
      end

      def claims_not_started_verification
        unverified_claims.merge(Eligibility.where(provider_verification_started_at: nil))
      end

      def claims_not_started_and_overdue_verification
        claims_not_started_verification.where(claims: {created_at: ..2.weeks.ago})
      end

      def claims_in_progress
        unverified_claims.merge(Eligibility.where.not(provider_verification_started_at: nil))
      end

      def claims_in_progress_and_overdue_verification
        claims_in_progress.where(claims: {created_at: ..2.weeks.ago})
      end

      def unverified_claims
        claims.fe_provider_unverified
      end

      def name
        school.name
      end

      private

      def school
        School.where("schools.ukprn::integer = ?", ukprn.to_i).first
      end
    end
  end
end
