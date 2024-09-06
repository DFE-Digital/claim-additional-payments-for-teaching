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
        @applicable_task_names ||= Task::NAMES.dup.tap do |task_names|
          task_names.delete("employment") if claim.eligibility.teacher_reference_number.blank?

          task_names.delete("induction_confirmation") unless claim.policy == Policies::EarlyCareerPayments
          task_names.delete("student_loan_amount") unless claim.policy == Policies::StudentLoans
          task_names.delete("student_loan_plan") unless claim.has_ecp_or_lupp_policy? && claim.submitted_without_slc_data?
          task_names.delete("payroll_details") unless claim.must_manually_validate_bank_details?
          task_names.delete("matching_details") unless matching_claims.exists?
          task_names.delete("payroll_gender") unless claim.payroll_gender_missing? || task_names_for_claim.include?("payroll_gender")

          unless claim.policy.international_relocation_payments?
            task_names.delete("visa")
            task_names.delete("arrival_date")
            task_names.delete("employment_contract")
            task_names.delete("employment_start")
            task_names.delete("subject")
            task_names.delete("teaching_hours")
          end
        end
      end

      private

      def task_names_for_claim
        claim.tasks.pluck(:name)
      end

      def matching_claims
        @matching_claims ||= Claim::MatchingAttributeFinder.new(claim).matching_claims
      end
    end
  end
end
