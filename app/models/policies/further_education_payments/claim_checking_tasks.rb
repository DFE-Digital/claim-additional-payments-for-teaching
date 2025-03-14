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

      private

      def matching_claims
        @matching_claims ||= Claim::MatchingAttributeFinder.new(claim).matching_claims
      end
    end
  end
end
