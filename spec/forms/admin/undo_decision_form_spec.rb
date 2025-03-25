require "rails_helper"

RSpec.describe Admin::UndoDecisionForm, type: :model do
  let(:current_admin) { create(:dfe_signin_user) }
  let(:decision) { claim.decisions.first }

  subject do
    described_class.new(
      claim:,
      decision:,
      current_admin:,
      params: {
        notes: "some note"
      }
    )
  end

  describe "validations" do
    context "when high risk and not a service admin" do
      let(:claim) { create(:claim, :rejected, :high_risk) }

      it "is not valid" do
        expect(subject).to be_invalid
        expect(subject.errors[:base]).to eql(["This claim can only have its decision undone by an SRO"])
      end
    end
  end
end
