# frozen_string_literal: true

module Policies
  module EarlyYearsPayments
    class ClaimCheckingTasks
      attr_reader :claim

      def initialize(claim)
        @claim = claim
      end

      delegate :policy, to: :claim

      def applicable_task_names
        tasks = []

        if year_1_of_ey?
          tasks << "identity_confirmation"
        else
          tasks << "one_login_identity"
          tasks << "ey_alternative_verification" if claim.failed_one_login_idv?
        end
        tasks << "employment"
        tasks << "student_loan_plan" if claim.submitted_without_slc_data?
        tasks << "payroll_details" if claim.must_manually_validate_bank_details?
        tasks << "payroll_gender" if claim.payroll_gender_missing? || claim.tasks.exists?(name: "payroll_gender")
        tasks << "matching_details" if matching_claims.exists?

        tasks
      end

      def applicable_task_objects
        applicable_task_names.map do |name|
          OpenStruct.new(name:, locale_key: name)
        end
      end

      private

      def year_1_of_ey?
        claim.academic_year == AcademicYear.new("2024/2025")
      end

      def matching_claims
        @matching_claims ||= Claim::MatchingAttributeFinder.new(claim).matching_claims
      end
    end
  end
end
