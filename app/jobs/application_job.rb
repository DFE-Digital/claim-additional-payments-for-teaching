class ApplicationJob < ActiveJob::Base
  include Rollbar::ActiveJob

  around_perform do |job, block|
    claim = job.arguments.find { |arg| arg.is_a?(Claim) }

    if claim
      Rollbar.scope!(claim: {reference: claim.reference})
    end

    block.call
  end

  def priority
    10
  end
end
