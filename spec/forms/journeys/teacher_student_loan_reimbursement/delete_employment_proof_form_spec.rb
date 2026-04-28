require "rails_helper"

RSpec.describe Journeys::TeacherStudentLoanReimbursement::DeleteEmploymentProofForm do
  let(:journey) { Journeys::TeacherStudentLoanReimbursement }
  let(:blob) { create(:active_storage_blob) }

  let(:journey_session) do
    create(:student_loans_session, answers: {confirmed_employment_proof_blob_ids: [blob.id.to_s]})
  end

  before { journey_session.employment_proofs.attach(blob) }

  let(:params) do
    ActionController::Parameters.new(
      blob_id: blob.id,
      claim: {confirmed: confirmed, blob_id: blob.id}
    )
  end

  let(:form) do
    described_class.new(
      journey: journey,
      journey_session: journey_session,
      params: params
    )
  end

  describe "validations" do
    subject { form }

    context "when confirmed is 'yes'" do
      let(:confirmed) { "yes" }

      it { is_expected.to be_valid }
    end

    context "when confirmed is 'no'" do
      let(:confirmed) { "no" }

      it { is_expected.to be_valid }
    end

    context "when confirmed is blank" do
      let(:confirmed) { nil }

      it { is_expected.not_to be_valid }

      it "has an appropriate error message" do
        form.valid?
        expect(form.errors[:confirmed]).to include("Select yes to delete this file")
      end
    end
  end

  describe "#save" do
    context "when confirmed is 'yes'" do
      let(:confirmed) { "yes" }

      it "purges the attachment" do
        expect { form.save }.to change { journey_session.employment_proofs.count }.by(-1)
      end

      it "removes the blob id from confirmed_employment_proof_blob_ids" do
        form.save
        expect(journey_session.reload.answers.confirmed_employment_proof_blob_ids).not_to include(blob.id.to_s)
      end

      it "always returns false" do
        expect(form.save).to be false
      end
    end

    context "when confirmed is 'no'" do
      let(:confirmed) { "no" }

      it "does not purge the attachment" do
        expect { form.save }.not_to change { journey_session.employment_proofs.count }
      end

      it "does not modify confirmed_employment_proof_blob_ids" do
        form.save
        expect(journey_session.reload.answers.confirmed_employment_proof_blob_ids).to include(blob.id.to_s)
      end

      it "returns false" do
        expect(form.save).to be false
      end
    end

    context "when invalid" do
      let(:confirmed) { nil }

      it "returns false" do
        expect(form.save).to be false
      end
    end

    context "when blob_id does not belong to this session" do
      let(:confirmed) { "yes" }
      let(:other_blob) { create(:active_storage_blob) }

      let(:params) do
        ActionController::Parameters.new(
          blob_id: other_blob.id,
          claim: {confirmed: confirmed, blob_id: other_blob.id}
        )
      end

      it "does not purge any attachment" do
        expect { form.save }.not_to change { journey_session.employment_proofs.count }
      end
    end
  end

  describe "#redirect?" do
    context "when confirmed is 'yes'" do
      let(:confirmed) { "yes" }

      it { expect(form.redirect?).to be true }
    end

    context "when confirmed is 'no'" do
      let(:confirmed) { "no" }

      it { expect(form.redirect?).to be true }
    end

    context "when confirmed is blank" do
      let(:confirmed) { nil }

      it { expect(form.redirect?).to be false }
    end
  end

  describe "#redirect_to" do
    context "when confirmed is 'yes' and no blobs remain" do
      let(:confirmed) { "yes" }

      before do
        journey_session.answers.confirmed_employment_proof_blob_ids.clear
        journey_session.save!
      end

      it "redirects to upload-employment-proof" do
        expect(form.redirect_to).to include("upload-employment-proof")
        expect(form.redirect_to).not_to include("uploaded-employment-proof")
      end
    end

    context "when confirmed is 'no'" do
      let(:confirmed) { "no" }

      it "redirects to uploaded-employment-proof" do
        expect(form.redirect_to).to include("uploaded-employment-proof")
      end
    end
  end

  describe "#redirect_to_next_slug?" do
    context "when blob_id is present in params" do
      let(:confirmed) { "yes" }

      it { expect(form.redirect_to_next_slug?).to be false }
    end

    context "when blob_id is absent from params" do
      let(:confirmed) { nil }
      let(:params) { ActionController::Parameters.new(claim: {confirmed: nil}) }

      it { expect(form.redirect_to_next_slug?).to be true }
    end
  end

  describe "#blob_to_delete" do
    let(:confirmed) { "yes" }

    it "returns the blob scoped to the session" do
      expect(form.blob_to_delete).to eq(blob)
    end

    context "when blob_id does not belong to this session" do
      let(:other_blob) { create(:active_storage_blob) }

      let(:params) do
        ActionController::Parameters.new(
          blob_id: other_blob.id,
          claim: {confirmed: "yes", blob_id: other_blob.id}
        )
      end

      it "returns nil" do
        expect(form.blob_to_delete).to be_nil
      end
    end
  end

  describe "#completed?" do
    let(:confirmed) { "yes" }

    it { expect(form.completed?).to be true }
  end
end
