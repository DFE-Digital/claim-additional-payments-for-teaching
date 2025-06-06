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

        tasks << "first_year_payment" unless claim.tasks.previous_payment.exists?
        tasks << "previous_payment" if claim.tasks.previous_payment.exists?
        tasks << "identity_confirmation"
        tasks << "visa"
        tasks << "arrival_date"
        tasks << "previous_residency"
        tasks << "employment"
        tasks << "employment_contract" if claim.tasks.exists?(name: "employment_contract")
        tasks << "employment_start" if claim.tasks.exists?(name: "employment_start")
        tasks << "continuous_employment"
        tasks << "subject" if claim.tasks.exists?(name: "subject")
        tasks << "employment_history" if claim.eligibility.changed_workplace_or_new_contract?
        tasks << "teaching_hours"
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
