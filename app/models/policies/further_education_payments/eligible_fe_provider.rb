module Policies
  module FurtherEducationPayments
    class EligibleFeProvider < ApplicationRecord
      module ClaimScopes
        def unverified
          merge(
            Policies::FurtherEducationPayments::Eligibility
              .where(provider_verification_completed_at: nil)
              .where(repeat_applicant_check_passed: true)
          )
        end

        def verified
          merge(
            Policies::FurtherEducationPayments::Eligibility
              .where.not(provider_verification_completed_at: nil)
          )
        end

        def verification_overdue
          where(claims: {created_at: ..2.weeks.ago})
        end

        def verification_not_started
          merge(Eligibility.where(provider_verification_started_at: nil))
        end

        def verification_in_progress
          merge(Eligibility.where.not(provider_verification_started_at: nil))
        end
      end

      attribute :academic_year, AcademicYear::Type.new
      belongs_to :file_upload

      scope :by_academic_year, ->(academic_year) {
        where(file_upload: FileUpload.latest_version_for(EligibleFeProvider, academic_year))
      }

      has_one :school,
        primary_key: :ukprn,
        foreign_key: :ukprn,
        class_name: "School"

      has_many :eligibilities,
        class_name: "Policies::FurtherEducationPayments::Eligibility",
        through: :school,
        source: :further_education_payments_eligibilities

      has_many :claims,
        -> { extending ClaimScopes },
        through: :eligibilities,
        source: :claim

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

      def name
        school.name
      end
    end
  end
end
