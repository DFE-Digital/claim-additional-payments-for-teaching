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

    private

    def skip_matching_claims_check?
      !!@skip_matching_claims_check
    end

    def matching_claims
      return @matching_claims if defined?(@matching_claims)

      return Claim.none if skip_matching_claims_check?

      @matching_claims = Claim::MatchingAttributeFinder.new(claim).matching_claims
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
