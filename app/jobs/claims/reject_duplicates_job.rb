module Claims
  class RejectDuplicatesJob < ApplicationJob
    # There's 99 duplicates to reject so ok to do this inline
    def perform(references)
      failed_rejections = []

      current_admin = DfeSignIn::User.find_by!(email: "Richard2.LYNCH@education.gov.uk")

      duplicates = Claim.awaiting_decision.where(reference: references)

      duplicates.each do |claim|
        rejection_reason = if claim.policy::ADMIN_DECISION_REJECTED_REASONS.include?(:duplicate)
          :duplicate
        else
          :duplicate_claim
        end

        decision = claim.decisions.build(
          approved: false,
          notes: "Rejected duplicate from March 2nd launch - email not sent",
          rejected_reasons: {
            rejection_reason => "1"
          },
          created_by: current_admin
        )

        failed_rejections << decision unless decision.save

        task = claim.tasks.find_or_initialize_by(name: "matching_details")

        task.assign_attributes(
          passed: false,
          manual: false,
          created_by: current_admin
        )

        task.save!

        Event.create(
          claim:,
          name: "claim_rejected",
          actor: current_admin,
          entity: decision
        )
      end

      failed_rejections.each do |decision|
        puts "#{decision.claim.reference} - #{decision.errors.full_messages}"
      end
    end
  end
end
