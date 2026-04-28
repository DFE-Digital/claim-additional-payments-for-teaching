require "rails_helper"

RSpec.describe Journeys::TeacherStudentLoanReimbursement::UploadedEmploymentProofForm do
  let(:journey) { Journeys::TeacherStudentLoanReimbursement }
  let(:blob) { create(:active_storage_blob) }

  let(:journey_session) do
    create(:student_loans_session, answers: {confirmed_employment_proof_blob_ids: [blob.id.to_s]})
  end

  let(:params) do
    ActionController::Parameters.new(claim: {upload_another: upload_another})
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

    context "when upload_another is 'yes'" do
      let(:upload_another) { "yes" }

      it { is_expected.to be_valid }
    end

    context "when upload_another is 'no'" do
      let(:upload_another) { "no" }

      it { is_expected.to be_valid }
    end

    context "when upload_another is blank" do
      let(:upload_another) { nil }

      it { is_expected.not_to be_valid }

      it "has an appropriate error message" do
        form.valid?
        expect(form.errors[:upload_another]).to include("Select yes if you want to upload another document")
      end
    end
  end

  describe "#save" do
    context "when upload_another is 'no'" do
      let(:upload_another) { "no" }

      it { expect(form.save).to be true }
    end

    context "when upload_another is 'yes'" do
      let(:upload_another) { "yes" }

      it { expect(form.save).to be false }
    end

    context "when invalid" do
      let(:upload_another) { nil }

      it { expect(form.save).to be false }
    end
  end

  describe "#redirect?" do
    context "when upload_another is 'yes'" do
      let(:upload_another) { "yes" }

      it { expect(form.redirect?).to be true }
    end

    context "when upload_another is 'no'" do
      let(:upload_another) { "no" }

      it { expect(form.redirect?).to be false }
    end
  end

  describe "#redirect_to" do
    let(:upload_another) { "yes" }

    it "redirects to upload-employment-proof" do
      expect(form.redirect_to).to include("upload-employment-proof")
    end
  end

  describe "#uploaded_blobs" do
    let(:upload_another) { "no" }

    it "returns blobs for confirmed ids in created_at order" do
      expect(form.uploaded_blobs).to include(blob)
    end
  end

  describe "#completed?" do
    let(:upload_another) { "no" }

    context "when confirmed_employment_proof_blob_ids has entries" do
      it { expect(form.completed?).to be true }
    end

    context "when confirmed_employment_proof_blob_ids is empty" do
      let(:journey_session) { create(:student_loans_session) }

      it { expect(form.completed?).to be false }
    end
  end
end
