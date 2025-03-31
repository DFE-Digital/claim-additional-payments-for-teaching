# frozen_string_literal: true

module Policies
  module TargetedRetentionIncentivePayments
    class ClaimCheckingTasks
      attr_reader :claim

      def initialize(claim)
        @claim = claim
      end

      delegate :policy, to: :claim

      def applicable_task_names
        tasks = []

        tasks << "identity_confirmation"
        tasks << "qualifications"
        tasks << "census_subjects_taught"
        tasks << "employment"
        tasks << "student_loan_plan" if claim.submitted_without_slc_data?
        tasks << "payroll_details" if claim.must_manually_validate_bank_details?
        tasks << "matching_details" if matching_claims.exists?
        tasks << "payroll_gender" if claim.payroll_gender_missing? || claim.tasks.exists?(name: "payroll_gender")

        tasks
      end

      def applicable_task_objects
        applicable_task_names.map do |name|
          OpenStruct.new(name:, locale_key: name)
        end
      end

      private

      def matching_claims
        @matching_claims ||= Claim::MatchingAttributeFinder.new(claim).matching_claims
      end
    end
  end
end
