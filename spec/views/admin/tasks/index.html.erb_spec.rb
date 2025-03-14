require "rails_helper"

RSpec.describe "admin/tasks/index.html.erb" do
  context "FE claim" do
    let(:claim) do
      create(
        :claim,
        :submitted,
        policy: Policies::FurtherEducationPayments
      )
    end

    let(:claim_checking_tasks) do
      ClaimCheckingTasks.new(claim)
    end

    before do
      allow(view).to receive(:current_page?).and_return(true)
    end

    context "when alternative_idv feature flag enabled", feature_flag: :alternative_idv do
      it "ues new task names" do
        assign(:claim, claim)
        assign(:claim_checking_tasks, claim_checking_tasks)
        assign(:banner_messages, [])

        render

        expect(rendered).to include("One Login identity check")
        expect(rendered).to include("Eligibility check")

        expect(rendered).not_to include("Identity confirmation")
        expect(rendered).not_to include("Provider verification")
      end
    end

    context "when alternative_idv feature flag disabled" do
      it "ues old task names" do
        assign(:claim, claim)
        assign(:claim_checking_tasks, claim_checking_tasks)
        assign(:banner_messages, [])

        render

        expect(rendered).to include("Identity confirmation")
        expect(rendered).to include("Provider verification")

        expect(rendered).not_to include("One Login identity check")
        expect(rendered).not_to include("Eligibility check")
      end
    end
  end
end
