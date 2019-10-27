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
  attr_reader :claim, :context, :params

  def initialize(claim, params, context)
    @claim = claim
    @params = params
    @context = context.to_sym
  end

  def perform
    claim.attributes = params
    claim.reset_dependent_answers
    claim.eligibility.reset_dependent_answers
    claim.save(context: context)
  end
end
