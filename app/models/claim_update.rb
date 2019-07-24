# frozen_string_literal: true

# Performs an update on a claim in the context of a user performing an action
# through the user interface. The `context` tells the object the page on which
# the user is performing the action, enabling it to carry out actions and
# validations on the claim that are appropriate to that context. For example,
# Performing an update in the "check-your-answers" context will attempt to
# submit the claim and send the confirmation email to the claimant.
#
# The `DEPENDENT_ANSWERS` hash defines the attributes that depend on the value
# of another attribute such that if the value of the other attribute changes
# the dependent attribute should be reset because the value will no longer hold,
# or may be an answer to a question that should no longer be asked. For example,
# the `student_loan_course` attribute should only be set if the user
# `has_student_loan`.
class ClaimUpdate
  DEPENDENT_ANSWERS = {
    "claim_school_id" => "employment_status",
    "has_student_loan" => "student_loan_country",
    "student_loan_country" => "student_loan_courses",
    "student_loan_courses" => "student_loan_start_date",
  }.freeze

  attr_reader :claim, :context, :params

  def initialize(claim, params, context)
    @claim = claim
    @params = params
    @context = context.to_sym
  end

  def perform
    if submitting_claim?
      claim.submit! && send_confirmation_email
    else
      claim.attributes = params

      reset_dependent_answers

      infer_current_school
      determine_student_loan_plan

      claim.save(context: context)
    end
  end

  private

  def submitting_claim?
    context == :"check-your-answers"
  end

  def send_confirmation_email
    ClaimMailer.submitted(claim).deliver_later
  end

  def reset_dependent_answers
    DEPENDENT_ANSWERS.each do |attribute_name, dependent_attribute_name|
      if claim.changed.include?(attribute_name)
        claim.attributes = {dependent_attribute_name => nil}
      end
    end
  end

  def infer_current_school
    if claim.employment_status_changed?
      claim.current_school = claim.employed_at_claim_school? ? claim.claim_school : nil
    end
  end

  def determine_student_loan_plan
    claim.student_loan_plan = if claim.has_student_loan?
      StudentLoans.determine_plan(claim.student_loan_country, claim.student_loan_start_date)
    else
      TslrClaim::NO_STUDENT_LOAN
    end
  end
end
