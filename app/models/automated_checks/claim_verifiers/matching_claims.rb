module AutomatedChecks
  module ClaimVerifiers
    class MatchingClaims
      def initialize(claim:)
        @source_claim = claim
      end

      def perform
        finder = Claim::MatchingAttributeFinder.new(source_claim)

        existing_matches = Claims::Match.matching_claims(source_claim)

        current_matches = finder.matching_claims

        removed_matches = existing_matches - current_matches

        ApplicationRecord.transaction do
          removed_matches.each do |removed_match|
            remove_match!(source_claim, removed_match)
            remove_match!(removed_match, source_claim)
          end

          current_matches.each do |matching_claim|
            record_match!(source_claim, matching_claim)
            record_match!(matching_claim, source_claim)
          end
        end
      end

      private

      attr_reader :source_claim

      def record_match!(target_claim, duplicate_claim)
        return unless task_updateable?(target_claim)

        task = target_claim.tasks.matching_details.last || target_claim.tasks.matching_details.new

        data = task.data || {}

        matches = Set.new(data["matching_claims"])

        matches << duplicate_claim.reference

        data["matching_claims"] = matches.to_a

        task.data = data

        task.save!(context: :claim_verifier)
      end

      def remove_match!(target_claim, duplicate_claim)
        return unless task_updateable?(target_claim)

        task = target_claim.tasks.matching_details.last

        # If for some reason there isn't a task there's nothing to do
        return unless task

        data = task.data || {}

        matches = Set.new(data["matching_claims"])
        matches = matches.excluding(duplicate_claim.reference)

        if matches.empty?
          task.destroy!
        else
          data["matching_claims"] = matches.to_a
          task.data = data
          task.save!(context: :claim_verifier)
        end
      end

      def task_updateable?(claim)
        # Don't change the tasks history on a decided claim.
        # If a new match has been found since the matching details task wass
        # completed we don't change the task, though we will still show the
        # warning, this is the existing behaviour.
        if claim.decision_made? || claim.tasks.matching_details.last&.completed?
          false
        else
          true
        end
      end
    end
  end
end
