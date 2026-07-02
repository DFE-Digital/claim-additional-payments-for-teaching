module Policies
  class ClaimCheckingTasks
    attr_reader :claim

    def initialize(claim, skip_persisting_tasks_shim: false)
      @claim = claim
      @skip_persisting_tasks_shim = skip_persisting_tasks_shim
    end

    delegate :policy, to: :claim

    def applicable_task_objects
      applicable_task_names.map do |name|
        OpenStruct.new(name:, locale_key: name)
      end
    end

    def blocking_approval
      all_tasks
        .select(&:blocks_approval?)
        .select(&:not_passed?)
    end

    def identity_status
      task = claim.tasks.detect { |t| t.name == "identity_confirmation" }

      if task.nil?
        "Unverified"
      elsif task.passed?
        "Passed"
      elsif task.passed == false
        "Failed"
      elsif task.claim_verifier_match_all?
        "Full match"
      elsif task.claim_verifier_match_any?
        "Partial match"
      elsif task.claim_verifier_match_none?
        "No match"
      end
    end

    private

    def all_tasks
      @all_tasks ||= applicable_task_names.map do |name|
        # Not using `claim.tasks.find_or_initialize_by` here as we don't want to
        # modify `claim.tasks`.
        claim.tasks.find_by(name: name) || Task.new(name: name, claim:)
      end
    end

    def skip_persisting_tasks_shim?
      !!@skip_persisting_tasks_shim
    end

    def matching_claims
      return @matching_claims if defined?(@matching_claims)

      @matching_claims = Claims::Match.matches_shim(claim)
    end

    def task_exists?(name)
      if claim.tasks.loaded?
        claim.tasks.any? { |task| task.name == name }
      else
        claim.tasks.exists?(name: name)
      end
    end

    # Temporary shim until all claims have a persisted matching details task
    def persisting_tasks_shim(name)
      # Skip the shim if we're rendering the admin task list page otherwise it
      # will slow to a crawl!
      return if skip_persisting_tasks_shim?

      if name == "matching_details" && !task_exists?(name)
        AutomatedChecks::ClaimVerifiers::MatchingClaims.new(claim: claim).perform
      end
    end
  end
end
