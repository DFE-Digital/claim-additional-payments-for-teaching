require "rails_helper"
require Rails.root.join("db", "data", "20191029113201_backfill_note_on_already_checked_claims")

RSpec.describe BackfillNoteOnAlreadyCheckedClaims do
  it "updates notes on already checked claims" do
    approved_claims = create_list(:claim, 3, :approved)
    rejected_claims = create_list(:claim, 2, :rejected)
    claim_without_check = create(:claim, :submitted)

    data = [
      "#{approved_claims[0].reference},First note",
      "#{approved_claims[1].reference},Second note",
      "#{approved_claims[2].reference},Third note",
      "#{claim_without_check.reference},This won't work",
      "FAKE_CLAIM_ID,This also won't work",
      "#{rejected_claims[0].reference},Fourth note",
      "#{rejected_claims[1].reference},Fifth note",
    ].join("|")

    ClimateControl.modify NOTES_TO_BACKFILL: data do
      described_class.new.up

      expect(approved_claims[0].check.reload.notes).to eq("First note")
      expect(approved_claims[1].check.reload.notes).to eq("Second note")
      expect(approved_claims[2].check.reload.notes).to eq("Third note")
      expect(rejected_claims[0].check.reload.notes).to eq("Fourth note")
      expect(rejected_claims[1].check.reload.notes).to eq("Fifth note")

      expect(claim_without_check.reload.check).to be_nil
    end
  end
end
