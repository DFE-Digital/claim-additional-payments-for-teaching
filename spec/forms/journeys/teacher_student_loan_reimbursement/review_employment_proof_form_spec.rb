require "rails_helper"

RSpec.describe Journeys::TeacherStudentLoanReimbursement::ReviewEmploymentProofForm do
  let(:journey) { Journeys::TeacherStudentLoanReimbursement }
  let(:blob) { create(:active_storage_blob) }
  let(:journey_session) { create(:student_loans_session) }

  before { journey_session.employment_proofs.attach(blob) }

  let(:params) do
    ActionController::Parameters.new(
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
        expect(form.errors[:confirmed]).to include("Select yes if the file is correct")
      end
    end
  end

  describe "#save" do
    context "when confirmed is 'yes'" do
      let(:confirmed) { "yes" }

      it "adds the blob id to confirmed_employment_proof_blob_ids" do
        form.save
        expect(journey_session.reload.answers.confirmed_employment_proof_blob_ids).to include(blob.id.to_s)
      end

      it "does not purge the attachment" do
        expect { form.save }.not_to change { journey_session.employment_proofs.count }
      end

      it "returns true" do
        expect(form.save).to be true
      end

      context "when blob is already confirmed" do
        before do
          journey_session.answers.confirmed_employment_proof_blob_ids << blob.id.to_s
          journey_session.save!
        end

        it "does not add a duplicate" do
          form.save
          expect(
            journey_session.reload.answers.confirmed_employment_proof_blob_ids.count(blob.id.to_s)
          ).to eq(1)
        end
      end
    end

    context "when confirmed is 'no'" do
      let(:confirmed) { "no" }

      it "purges the attachment" do
        expect { form.save }.to change { journey_session.employment_proofs.count }.by(-1)
      end

      it "returns false" do
        expect(form.save).to be false
      end

      it "does not add the blob id to confirmed list" do
        form.save
        expect(journey_session.reload.answers.confirmed_employment_proof_blob_ids).to be_empty
      end
    end

    context "when invalid" do
      let(:confirmed) { nil }

      it "returns false" do
        expect(form.save).to be false
      end
    end
  end

  describe "#redirect?" do
    context "when confirmed is 'no'" do
      let(:confirmed) { "no" }

      it { expect(form.redirect?).to be true }
    end

    context "when confirmed is 'yes'" do
      let(:confirmed) { "yes" }

      it { expect(form.redirect?).to be false }
    end
  end

  describe "#redirect_to" do
    context "when no blobs are confirmed" do
      let(:confirmed) { "no" }

      it "redirects to upload-employment-proof" do
        expect(form.redirect_to).to include("upload-employment-proof")
        expect(form.redirect_to).not_to include("uploaded-employment-proof")
      end
    end

    context "when blobs are already confirmed" do
      let(:confirmed) { "no" }

      before do
        journey_session.answers.confirmed_employment_proof_blob_ids << "some-other-blob-id"
        journey_session.save!
      end

      it "redirects to uploaded-employment-proof" do
        expect(form.redirect_to).to include("uploaded-employment-proof")
      end
    end
  end

  describe "#latest_blob" do
    let(:confirmed) { "yes" }

    it "returns the most recently attached blob" do
      expect(form.latest_blob).to eq(blob)
    end
  end

  describe "#completed?" do
    let(:confirmed) { "yes" }

    context "when confirmed_employment_proof_blob_ids is empty" do
      it { expect(form.completed?).to be false }
    end

    context "when confirmed_employment_proof_blob_ids has entries" do
      before do
        journey_session.answers.confirmed_employment_proof_blob_ids << blob.id.to_s
        journey_session.save!
      end

      it { expect(form.completed?).to be true }
    end
  end
end
