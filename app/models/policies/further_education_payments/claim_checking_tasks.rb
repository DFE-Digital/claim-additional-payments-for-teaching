# frozen_string_literal: true

module Policies
  module FurtherEducationPayments
    class ClaimCheckingTasks
      attr_reader :claim

      def initialize(claim)
        @claim = claim
      end

      delegate :policy, to: :claim

      def applicable_task_names
        tasks = []

        tasks << "one_login_identity"
        tasks << "provider_verification"
        tasks << "provider_details" if claim.eligibility.provider_and_claimant_details_match?
        tasks << "alternative_identity_verification" if show_alternative_identity_verification_task?
        tasks << "alternative_verification" if show_alternative_verification_task?
        tasks << "employment" if claim.eligibility.teacher_reference_number.present?
        tasks << "student_loan_plan" if claim.submitted_without_slc_data?
        tasks << "payroll_details" if claim.must_manually_validate_bank_details?
        tasks << "matching_details" if matching_claims.exists?
        tasks << "payroll_gender" if claim.payroll_gender_missing? || claim.tasks.exists?(name: "payroll_gender")

        tasks
      end

      def applicable_task_objects
        applicable_task_names.map do |name|
          if FeatureFlag.disabled?(:alternative_idv) && name == "one_login_identity"
            OpenStruct.new(name:, locale_key: "identity_confirmation")
          elsif FeatureFlag.enabled?(:alternative_idv) && name == "provider_verification"
            OpenStruct.new(name:, locale_key: "eligibility_check")
          else
            OpenStruct.new(name:, locale_key: name)
          end
        end
      end

      def incomplete_task_names
        applicable_task_names - task_names_for_claim
      end

      private

      def matching_claims
        @matching_claims ||= Claim::MatchingAttributeFinder.new(claim).matching_claims
      end

      def task_names_for_claim
        claim.tasks.pluck(:name)
      end

      def show_alternative_identity_verification_task?
        y1_fe_claim = claim.academic_year == AcademicYear.new("2024/2025")

        claim.failed_one_login_idv? && y1_fe_claim
      end

      def show_alternative_verification_task?
        claim.failed_one_login_idv?
      end
    end
  end
end
