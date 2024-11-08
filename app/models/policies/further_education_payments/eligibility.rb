module Policies
  module FurtherEducationPayments
    class Eligibility < ApplicationRecord
      AMENDABLE_ATTRIBUTES = [].freeze

      self.table_name = "further_education_payments_eligibilities"

      class Course < Struct.new(:subject, :name, keyword_init: true)
        include Journeys::FurtherEducationPayments::CoursesHelper

        def taught?
          name != "none"
        end

        def description
          I18n.t(
            "further_education_payments.forms.#{subject}_courses.options.#{name}",
            link: link_for_course("#{subject}_courses", name)
          )
        end
      end

      has_one :claim, as: :eligibility, inverse_of: :eligibility

      belongs_to :possible_school, optional: true, class_name: "School"
      belongs_to :school, optional: true

      scope :unverified, -> { where(verification: {}) }
      scope :provider_verification_email_last_sent_over, ->(older_than) { where("provider_verification_email_last_sent_at < ?", older_than) }
      scope :provider_verification_chase_email_not_sent, -> { where(provider_verification_chase_email_last_sent_at: nil) }

      # Claim#school expects this
      alias_method :current_school, :school

      def policy
        Policies::FurtherEducationPayments
      end

      def ineligible?
        false
      end

      def courses_taught
        courses.select(&:taught?)
      end

      def courses
        subjects_taught.map do |subject|
          public_send(:"#{subject}_courses").map do |course|
            Course.new(subject: subject, name: course)
          end
        end.flatten
      end

      def long_term_employed?
        case contract_type
        when "permanent"
          true
        when "variable_hours"
          false
        when "fixed_term"
          !!fixed_term_full_year
        end
      end

      def permanent_contract?
        contract_type == "permanent"
      end

      def verified?
        verification.present?
      end

      def awaiting_provider_verification?
        return false if verified?

        # when a provider verification email is sent by the admin team, a note is created
        !flagged_as_duplicate? || claim.notes.where(label: "provider_verification").any?
      end

      def provider_and_claimant_details_match?
        provider_and_claimant_names_match? || provider_and_claimant_emails_match?
      end

      def provider_full_name
        "#{provider_first_name} #{provider_last_name}"
      end

      def provider_email
        verification.dig("verifier", "email")
      end

      private

      def provider_and_claimant_names_match?
        return false unless verified?

        provider_first_name&.downcase == claim.first_name.downcase &&
          provider_last_name&.downcase == claim.surname.downcase
      end

      def provider_and_claimant_emails_match?
        return false unless verified?

        provider_email&.downcase == claim.email_address.downcase
      end

      def provider_first_name
        verification.dig("verifier", "first_name")
      end

      def provider_last_name
        verification.dig("verifier", "last_name")
      end
    end
  end
end
