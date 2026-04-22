require "rails_helper"

RSpec.describe Journeys::TeacherStudentLoanReimbursement::UploadEmploymentProofForm do
  let(:journey) { Journeys::TeacherStudentLoanReimbursement }
  let(:journey_session) { create(:student_loans_session) }
  let(:file) { Rack::Test::UploadedFile.new(StringIO.new("test content"), "application/pdf", original_filename: "document.pdf") }
  let(:params) { ActionController::Parameters.new(claim: {file: file}) }

  let(:form) do
    described_class.new(
      journey: journey,
      journey_session: journey_session,
      params: params
    )
  end

  describe "validations" do
    subject { form }

    context "when file is present" do
      it { is_expected.to be_valid }
    end

    context "when file is absent" do
      let(:params) { ActionController::Parameters.new(claim: {file: nil}) }

      it { is_expected.not_to be_valid }

      it "has an appropriate error message" do
        form.valid?
        expect(form.errors[:file]).to include("Select a file to upload")
      end
    end
  end

  describe "#save" do
    context "when valid" do
      it "attaches the file to the journey session" do
        expect { form.save }.to change { journey_session.employment_proofs.count }.by(1)
      end

      it "uses the journey session id as the blob key prefix" do
        form.save
        expect(journey_session.employment_proofs.first.blob.key).to start_with("#{journey_session.id}/")
      end

      it "returns true" do
        expect(form.save).to be true
      end
    end

    context "when invalid" do
      let(:params) { ActionController::Parameters.new(claim: {file: nil}) }

      it "does not attach any file" do
        expect { form.save }.not_to change { journey_session.employment_proofs.count }
      end

      it "returns false" do
        expect(form.save).to be false
      end
    end
  end

  describe "#completed?" do
    context "when a file is attached" do
      before { journey_session.employment_proofs.attach(io: StringIO.new("test"), filename: "test.pdf", content_type: "application/pdf") }

      it { expect(form.completed?).to be true }
    end

    context "when no file is attached" do
      it { expect(form.completed?).to be false }
    end
  end
end
