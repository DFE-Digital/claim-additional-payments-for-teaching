module Policies
  class ClaimCheckingTasks
    attr_reader :claim

    def initialize(claim, skip_matching_claims_check: false)
      @claim = claim
      @skip_matching_claims_check = skip_matching_claims_check
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

    def skip_matching_claims_check?
      !!@skip_matching_claims_check
    end

    def matching_claims
      return @matching_claims if defined?(@matching_claims)

      return Claim.none if skip_matching_claims_check?

      @matching_claims = Claims::Match.matching_claims_shim(claim)
    end

    def task_exists?(name)
      if claim.tasks.loaded?
        claim.tasks.any? { |task| task.name == name }
      else
        claim.tasks.exists?(name: name)
      end
    end
  end
end
