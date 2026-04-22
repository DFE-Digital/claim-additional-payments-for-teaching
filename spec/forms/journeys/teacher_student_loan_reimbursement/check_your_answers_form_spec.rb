require "rails_helper"

RSpec.describe Journeys::TeacherStudentLoanReimbursement::CheckYourAnswersForm do
  let(:journey) { Journeys::TeacherStudentLoanReimbursement }
  let(:journey_session) { create(:student_loans_session) }

  let(:form) do
    described_class.new(
      journey: journey,
      journey_session: journey_session,
      params: ActionController::Parameters.new(claim: {}),
      session: {}
    )
  end

  describe "#associate_confirmed_employment_proof_files" do
    let(:confirmed_blob) { create(:active_storage_blob) }
    let(:unconfirmed_blob) { create(:active_storage_blob) }

    let(:claim) { create(:claim) }

    before do
      journey_session.employment_proofs.attach(confirmed_blob)
      journey_session.employment_proofs.attach(unconfirmed_blob)
      journey_session.answers.confirmed_employment_proof_blob_ids << confirmed_blob.id.to_s
      journey_session.save!

      form.instance_variable_set(:@claim, claim)
    end

    it "attaches confirmed blobs to the claim eligibility" do
      form.send(:associate_confirmed_employment_proof_files)
      expect(claim.eligibility.employment_proofs.blobs).to include(confirmed_blob)
    end

    it "does not attach unconfirmed blobs to the claim eligibility" do
      form.send(:associate_confirmed_employment_proof_files)
      expect(claim.eligibility.employment_proofs.blobs).not_to include(unconfirmed_blob)
    end

    it "enqueues purge of unconfirmed attachments" do
      expect { form.send(:associate_confirmed_employment_proof_files) }
        .to have_enqueued_job(ActiveStorage::PurgeJob).once
    end

    it "does not enqueue purge for confirmed attachments" do
      expect { form.send(:associate_confirmed_employment_proof_files) }
        .not_to have_enqueued_job(ActiveStorage::PurgeJob).with(a_hash_including(blob_id: confirmed_blob.id))
    end

    it "removes unconfirmed blobs from the journey session after purge" do
      perform_enqueued_jobs do
        form.send(:associate_confirmed_employment_proof_files)
      end
      expect(journey_session.employment_proofs.blobs.reload).not_to include(unconfirmed_blob)
    end
  end
end
