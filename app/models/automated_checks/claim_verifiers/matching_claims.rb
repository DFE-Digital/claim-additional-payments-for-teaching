module AutomatedChecks
  module ClaimVerifiers
    class MatchingClaims
      def initialize(claim:)
        @source_claim = claim
      end

      def perform
        ApplicationRecord.transaction do
          result = Claims::Match.update_matching_claims!(source_claim)

          if result.removed_matches.any?
            # remove the matching details task from the other claims only if
            # * the task is not completed
            # * the other claim is not decided
            # * there are no _other_ match pairs on that claim
            result.removed_matches
              .select { |claim| Claims::Match.matching_claims(claim).none? }
              .select { |claim| task_updateable?(claim) }
              .each { |claim| remove_matching_details_task!(claim) }

            if task_updateable?(source_claim) && Claims::Match.matching_claims(source_claim).none?
              remove_matching_details_task!(source_claim)
            end
          end

          current_matches = result.new_matches + result.existing_matches

          if current_matches.any?
            # add the matching details task to matching claims only if
            # * the other claim doesn't already have the task
            # * the other claim is not decided
            current_matches
              .select { |claim| task_updateable?(claim) }
              .select { |claim| !already_has_task?(claim) }
              .each { |claim| add_matching_details_task!(claim) }

            if task_updateable?(source_claim) && !already_has_task?(source_claim)
              add_matching_details_task!(source_claim)
            end
          end
        end
      end

      private

      attr_reader :source_claim

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

      def already_has_task?(claim)
        claim.tasks.matching_details.exists?
      end

      def remove_matching_details_task!(claim)
        task = claim.tasks.matching_details.last
        task&.destroy!
      end

      def add_matching_details_task!(claim)
        task = claim.tasks.matching_details.new
        task.save!(context: :claim_verifier)
      end
    end
  end
end
