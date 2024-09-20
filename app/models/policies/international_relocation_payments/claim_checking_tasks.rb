# frozen_string_literal: true

module Policies
  module InternationalRelocationPayments
    class ClaimCheckingTasks
      attr_reader :claim

      def initialize(claim)
        @claim = claim
      end

      delegate :policy, to: :claim

      def applicable_task_names
        tasks = []

        tasks << "previous_payment"
        tasks << "identity_confirmation"
        tasks << "visa"
        tasks << "arrival_date"
        tasks << "employment"
        tasks << "employment_contract"
        tasks << "employment_start"
        tasks << "subject"
        tasks << "teaching_hours"
        tasks << "payroll_details" if claim.must_manually_validate_bank_details?
        tasks << "matching_details" if matching_claims.exists?
        tasks << "payroll_gender" if claim.payroll_gender_missing?

        tasks
      end

      private

      def matching_claims
        @matching_claims ||= Claim::MatchingAttributeFinder.new(claim).matching_claims
      end
    end
  end
end
