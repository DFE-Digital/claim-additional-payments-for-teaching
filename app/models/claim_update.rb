# frozen_string_literal: true

# Performs an update on a claim in the context of a user performing an action
# through the user interface. The `context` tells the object the page on which
# the user is performing the action, enabling it to carry out actions and
# validations on the claim that are appropriate to that context. For example,
# Performing an update in the "check-your-answers" context will attempt to
# submit the claim and send the confirmation email to the claimant.
class ClaimUpdate
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
      update_claim_school_dependent_attributes
      update_employment_status_dependent_attributes
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

  def update_claim_school_dependent_attributes
    if claim.claim_school_id_changed?
      claim.employment_status = nil
    end
  end

  def update_employment_status_dependent_attributes
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
