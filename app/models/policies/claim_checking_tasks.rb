module Policies
  class ClaimCheckingTasks
    attr_reader :claim

    def initialize(claim)
      @claim = claim
    end

    delegate :policy, to: :claim

    def applicable_task_objects
      applicable_task_names.map do |name|
        OpenStruct.new(name:, locale_key: name)
      end
    end

    private

    def matching_claims
      @matching_claims ||= Claim::MatchingAttributeFinder.new(claim).matching_claims
    end
  end
end
