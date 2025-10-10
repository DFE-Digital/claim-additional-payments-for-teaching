module Policies
  module FurtherEducationPayments
    class Eligibility < ApplicationRecord
      include ProviderVerificationConstants

      AMENDABLE_ATTRIBUTES = [:award_amount, :teacher_reference_number].freeze

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
      belongs_to :provider_assigned_to, class_name: "DfeSignIn::User", optional: true
      belongs_to :verified_by, class_name: "DfeSignIn::User", optional: true, foreign_key: :provider_verification_verified_by_id

      scope :unverified, -> { where(verification: {}) }
      scope :provider_verification_email_last_sent_over, ->(older_than) { where("provider_verification_email_last_sent_at < ?", older_than) }
      scope :provider_verification_chase_email_not_sent, -> { where(provider_verification_chase_email_last_sent_at: nil) }

      scope :awaiting_provider_verification_year_1, -> do
        joins(:claim).merge(Claim.by_academic_year(AcademicYear.new(2024)))
          .where(verification: {}, flagged_as_duplicate: false)
          .or(
            where(
              id: left_joins(claim: :notes)
              .where(
                verification: {},
                flagged_as_duplicate: true,
                notes: {label: "provider_verification"}
              )
              .select(:id)
            )
          )
      end

      scope :awaiting_provider_verification_year_2, -> do
        joins(:claim).merge(Claim.after_academic_year(AcademicYear.new(2024)))
          .where(provider_verification_completed_at: nil)
          .where(flagged_as_duplicate: false)
      end

      scope :awaiting_provider_verification, -> do
        where(
          id: awaiting_provider_verification_year_1.select(:id)
        ).or(
          where(id: awaiting_provider_verification_year_2.select(:id))
        )
      end

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
        if year_1_claim?
          verification.present?
        else
          provider_verification_completed_at.present?
        end
      end

      def awaiting_provider_verification?
        return false if verified?

        if year_1_claim?
          # when a provider verification email is sent by the admin team, a note is created
          !flagged_as_duplicate? || claim.notes.where(label: "provider_verification").any?
        else
          !flagged_as_duplicate?
        end
      end

      def provider_and_claimant_details_match?
        provider_and_claimant_names_match? || provider_and_claimant_emails_match?
      end

      def provider_full_name
        "#{provider_first_name} #{provider_last_name}"
      end

      def provider_email
        provider_user.email
      end

      def eligible_itt_subject
        nil
      end

      def verification_assertion(name)
        assertion_hash[name]
      end

      def provider_verification_status
        if provider_verification_rejected?
          STATUS_REJECTED
        elsif provider_verification_completed?
          STATUS_COMPLETED
        elsif provider_verification_overdue?
          STATUS_OVERDUE
        elsif provider_verification_started?
          STATUS_IN_PROGRESS
        else
          STATUS_NOT_STARTED
        end
      end

      def processed_by_label
        if provider_assigned_to
          provider_assigned_to.full_name
        else
          PROCESSED_BY_NOT_PROCESSED
        end
      end

      def provider_verification_started?
        provider_verification_started_at.present?
      end

      def provider_verification_rejected?
        claimant_not_employed_by_college?
      end

      def provider_verification_completed?
        provider_verification_completed_at.present?
      end

      def provider_verification_overdue?
        Policies::FurtherEducationPayments.verification_overdue?(claim)
      end

      def provider_verification_selected_at_least_one_eligible_course?
        [
          provider_verification_building_construction_courses,
          provider_verification_chemistry_courses,
          provider_verification_computing_courses,
          provider_verification_early_years_courses,
          provider_verification_engineering_manufacturing_courses,
          provider_verification_maths_courses,
          provider_verification_physics_courses
        ].flatten.count { |course| course != "none" } > 0
      end

      def employment_check_required?
        claim.failed_one_login_idv?
      end

      def alternative_identity_verification_required?
        employment_check_required?
      end

      def claimant_not_employed_by_college?
        provider_verification_claimant_employed_by_college == false
      end

      def planned_to_start_qualification_but_hasnt?
        previous_year_claim.present? &&
          previous_year_claim.eligibility.teaching_qualification == "no_but_planned" &&
          provider_verification_teaching_qualification.present? &&
          provider_verification_teaching_qualification == "no_but_planned"
      end

      def valid_reason_for_not_starting_qualification?
        provider_verification_not_started_qualification_reasons.exclude?("no_valid_reason")
      end

      def insufficient_teaching_hours_per_week?
        provider_verification_teaching_hours_per_week == "fewer_than_2_and_a_half_hours_per_week"
      end

      private

      def year_1_claim?
        claim.academic_year == AcademicYear.new(2024)
      end

      def provider_user
        if year_1_claim?
          @provider ||= OpenStruct.new(
            given_name: verification.dig("verifier", "first_name"),
            family_name: verification.dig("verifier", "last_name"),
            email: verification.dig("verifier", "email")
          )
        else
          verified_by
        end
      end

      def previous_year_claim
        Claim
          .by_policy(Policies::FurtherEducationPayments)
          .where(onelogin_uid: claim.onelogin_uid)
          .where(academic_year: claim.academic_year - 1)
          .order(created_at: :desc)
          .first
      end

      def provider_and_claimant_names_match?
        return false unless verified?

        provider_user.given_name&.downcase == claim.first_name.downcase &&
          provider_user.family_name&.downcase == claim.surname.downcase
      end

      def provider_and_claimant_emails_match?
        return false unless verified?

        provider_user&.email&.downcase == claim.email_address.downcase
      end

      def provider_first_name
        provider_user.given_name
      end

      def provider_last_name
        provider_user.family_name
      end

      def assertion_hash
        @assertion_hash ||= verification.fetch("assertions").map do |assertion|
          [assertion["name"], assertion["outcome"]]
        end.to_h
      end
    end
  end
end
