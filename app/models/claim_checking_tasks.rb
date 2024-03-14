# frozen_string_literal: true

# This models the tasks that need to be performed on a claim as part of the
# claim checking process.
class ClaimCheckingTasks
  attr_reader :claim

  def initialize(claim)
    @claim = claim
  end

  # TODO: Add Irp Specific tasks!
  def applicable_task_names
    @applicable_task_names ||= Task::NAMES.dup.tap do |task_names|
      task_names.delete("induction_confirmation") unless claim.policy == Policies::EarlyCareerPayments
      task_names.delete("student_loan_amount") unless claim.policy == StudentLoans
      task_names.delete("payroll_details") unless claim.must_manually_validate_bank_details?
      task_names.delete("matching_details") unless matching_claims.exists?
      task_names.delete("payroll_gender") unless claim.payroll_gender_missing? || task_names_for_claim.include?("payroll_gender")
      %w[
        identity_confirmation
        induction_confirmation
        census_subjects_taught
        employment
        student_loan_amount
        payroll_details
        matching_details
        qualifications
        payroll_gender
      ].each do |non_irp_task|
        task_names.delete(non_irp_task) if claim.policy == Irp
      end
      %w[
        irp_id_check irp_visa_type_check
        irp_date_of_entry
        irp_eligible_school irp_contract_length_check
        irp_contract_start_date_check irp_eligible_subject_check irp_fifty_percent_rule_check
      ].each do |irp_task|
        task_names.delete(irp_task) unless claim.policy == Irp
      end
    end
  end

  # Returns an Array of tasks names that have not been completed on the claim.
  def incomplete_task_names
    applicable_task_names - task_names_for_claim
  end

  def passed_automatically_task_names
    claim.tasks.passed_automatically.pluck(:name)
  end

  def all_tasks_passed_automatically?
    (applicable_task_names - passed_automatically_task_names).empty?
  end

  private

  def task_names_for_claim
    claim.tasks.pluck(:name)
  end

  def matching_claims
    @matching_claims ||= Claim::MatchingAttributeFinder.new(claim).matching_claims
  end
end
