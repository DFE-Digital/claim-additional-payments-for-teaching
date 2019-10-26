# frozen_string_literal: true

# Encapsulates a change being made by a user to their claim.
#
# Based on the changes being made, the answers to some related questions will be
# reset. For example, if the user changes their answer to the question asking if
# they have a student loan, then the answers to subsequent questions that depend
# on that question will be reset, i.e. the student loan country, number of
# courses and start date.
#
# Performs the update in the context the action is being performed in, thus
# context-specific validations will fire.
#
# Returns true if the update is successful, false otherwise.
class ClaimUpdate
  DEPENDENT_CLAIM_ANSWERS = {
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
    claim.attributes = params
    reset_dependent_claim_answers
    claim.eligibility.reset_dependent_answers
    claim.save(context: context)
  end

  private

  def reset_dependent_claim_answers
    DEPENDENT_CLAIM_ANSWERS.each do |attribute_name, dependent_attribute_name|
      if claim.changed.include?(attribute_name)
        claim.attributes = {dependent_attribute_name => nil}
      end
    end

    redetermine_student_loan_plan
  end

  def redetermine_student_loan_plan
    claim.student_loan_plan = if claim.has_student_loan?
      StudentLoans.determine_plan(claim.student_loan_country, claim.student_loan_start_date)
    else
      Claim::NO_STUDENT_LOAN
    end
  end
end
