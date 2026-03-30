require "rails_helper"

RSpec.describe Claims::RejectDuplicatesJob do
  describe "#perform" do
    it "rejects the claims and fails the matching details task" do
      admin = create(
        :dfe_signin_user,
        email: "Richard2.LYNCH@education.gov.uk"
      )

      claim = create(:claim, :submitted)

      described_class.perform_now([claim.reference])

      expect(claim).to be_rejected

      decision = claim.decisions.last

      expect(decision.approved).to be false
      expect(decision.notes).to eq "Rejected duplicate from March 2nd launch - email not sent"
      expect(decision.rejected_reasons).to eq "duplicate" => "1"
      expect(decision.created_by).to eq admin

      task = claim.tasks.find_by(name: "matching_details")

      expect(task.passed).to be false
      expect(task.manual).to be false
      expect(task.created_by).to eq admin

      event = claim.events.find_by(name: "claim_rejected")

      expect(event.actor).to eq admin
      expect(event.entity).to eq decision
    end
  end
end
