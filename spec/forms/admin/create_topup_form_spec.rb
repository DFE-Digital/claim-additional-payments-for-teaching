require "rails_helper"

RSpec.describe Admin::CreateTopupForm do
  let(:claim) { create(:claim, :approved) }

  let(:admin) { create(:dfe_signin_user) }

  let(:form) do
    described_class.new(claim: claim, created_by: admin, params: params)
  end

  describe "#complete?" do
    subject { form.complete? }

    context "when award_amount is missing" do
      let(:params) do
        {
          award_amount: nil,
          confirmation: true
        }
      end

      it { is_expected.to be false }
    end

    context "when not confirmed" do
      let(:params) do
        {
          award_amount: 100,
          confirmation: false
        }
      end

      it { is_expected.to be false }
    end

    context "when both are present" do
      let(:params) do
        {
          award_amount: 100,
          confirmation: true
        }
      end

      it { is_expected.to be true }
    end
  end

  describe "#save!" do
    context "when not complete" do
      let(:params) do
        {
          award_amount: 100
        }
      end

      it "raises" do
        expect do
          expect { form.save! }.to raise_error(ActiveRecord::RecordInvalid)
        end.to(change(Topup, :count).by(0).and(change(Note, :count).by(0)))
      end
    end

    context "when complete" do
      let(:params) do
        {
          award_amount: 100,
          confirmation: true
        }
      end

      before do
        travel_to 1.month.ago do
          create(:payment, claims: [claim])
        end
      end

      it "creates a topup and a note" do
        expect { expect(form.save!).to be true }.to(
          change(claim.topups, :count).by(1).and(change(Note, :count).by(1))
        )

        topup = claim.topups.last

        expect(topup.award_amount).to eq(100)

        expect(topup.created_by).to eq(admin)

        note = claim.notes.last

        expect(note.body).to eq("£100.00 top up added")

        expect(note.created_by).to eq(admin)
      end
    end
  end
end
