require "rails_helper"

RSpec.describe Admin::DestroyTopupForm do
  let(:admin) { create(:dfe_signin_user) }

  let(:topup) { create(:topup, award_amount: 100.55) }

  let(:claim) { topup.claim }

  let(:form) { described_class.new(topup: topup, removed_by: admin) }

  describe "#save" do
    context "when invalid" do
      before do
        create(:payment, topups: [topup])
      end

      it "returns false and sets errors" do
        expect { expect(form.save).to be false }.to(
          change(Topup, :count).by(0).and(change(Note, :count).by(0))
        )

        expect(form.errors[:base]).to(
          include("Top up cannot be removed if payrolled")
        )
      end
    end

    context "when valid" do
      it "removes a topup and creates a note" do
        expect { expect(form.save).to be true }.to(
          change(claim.topups, :count).by(-1).and(
            change(claim.notes, :count).by(1)
          )
        )

        note = claim.notes.last

        expect(note.body).to eq("£100.55 top up removed")

        expect(note.created_by).to eq(admin)
      end
    end
  end
end
