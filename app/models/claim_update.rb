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
end
