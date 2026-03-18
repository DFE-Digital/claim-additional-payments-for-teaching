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
  end
end
