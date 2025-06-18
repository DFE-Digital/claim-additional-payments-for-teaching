class ApplicationJob < ActiveJob::Base
  include Rollbar::ActiveJob

  around_perform do |job, block|
    claim = job.arguments.find { |arg| arg.is_a?(Claim) }

    if claim
      Rollbar.scope!(claim: {reference: claim.reference})

      Sentry.configure_scope do |scope|
        scope.set_context(
          "Claim",
          {
            reference: claim.reference
          }
        )
      end
    end

    block.call
  end

  def priority
    10
  end
end
