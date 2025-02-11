require "rails_helper"

RSpec.describe ClaimAutoApproval do
  subject(:claim_auto_approval) { described_class.new(claim) }

  let(:claim) { create(:claim, :submitted) }
  let(:applicable_task_names) { ClaimCheckingTasks.new(claim).applicable_task_names }

  describe "#eligible?" do
    subject { super().eligible? }

    context "when the claim is approved already" do
      let(:claim) { create(:claim, :approved) }

      it { is_expected.to eq(false) }
    end

    context "when the claim is rejected" do
      let(:claim) { create(:claim, :rejected) }

      it { is_expected.to eq(false) }
    end

    context "when the claim is held" do
      let(:claim) { create(:claim, :held) }

      it { is_expected.to eq(false) }
    end

    context "when the claim is a duplicate" do
      let(:claim) { create(:claim, :submitted) }
      let!(:duplicate) { create(:claim, :submitted, eligibility_attributes: {teacher_reference_number: claim.eligibility.teacher_reference_number}, policy: claim.policy) }

      it { is_expected.to eq(false) }
    end

    context "when the claim is awaiting QA" do
      let(:claim) { create(:claim, :flagged_for_qa) }

      it { is_expected.to eq(false) }
    end

    context "when all claim's tasks passed automatically" do
      before do
        applicable_task_names.each do |task|
          create(:task, :automated, :passed, name: task, claim:)
        end
      end

      it { is_expected.to eq(true) }
    end

    context "when some claim's tasks passed manually" do
      let(:passed_manually_tasks) { %w[employment student_loan_amount] }

      before do
        applicable_task_names.excluding(passed_manually_tasks).each do |task|
          create(:task, :automated, :passed, name: task, claim:)
        end

        passed_manually_tasks.each do |task|
          create(:task, :manual, :passed, name: task, claim:)
        end
      end

      it { is_expected.to eq(false) }
    end

    context "when some claim's tasks failed" do
      let(:failed_tasks) { %w[employment student_loan_amount] }

      before do
        applicable_task_names.excluding(failed_tasks).each do |task|
          create(:task, :automated, :passed, name: task, claim:)
        end

        failed_tasks.each do |task|
          create(:task, :automated, :failed, name: task, claim:)
        end
      end

      it { is_expected.to eq(false) }
    end

    context "when the census subjects taught task failed with NO DATA" do
      let(:failed_tasks) { %w[census_subjects_taught] }

      before do
        applicable_task_names.excluding(failed_tasks).each do |task|
          create(:task, :automated, :passed, name: task, claim:)
        end

        failed_tasks.each do |task|
          create(:task, :automated, :failed, name: task, claim:, claim_verifier_match: nil)
        end
      end

      it { is_expected.to eq(true) }
    end

    context "when the census subjects taught task failed with NO MATCH" do
      let(:failed_tasks) { %w[census_subjects_taught] }

      before do
        applicable_task_names.excluding(failed_tasks).each do |task|
          create(:task, :automated, :passed, name: task, claim:)
        end

        failed_tasks.each do |task|
          create(:task, :automated, :failed, name: task, claim:, claim_verifier_match: :none)
        end
      end

      it { is_expected.to eq(false) }
    end
  end

  describe "#auto_approve!" do
    subject(:auto_approve!) { claim_auto_approval.auto_approve! }

    before do
      allow(ClaimMailer).to receive(:approved).and_return(double(deliver_later: nil))
      allow(claim_auto_approval).to receive(:eligible?).and_return(eligible?)
      allow(claim_auto_approval).to receive(:passed_automatically_task_names)
        .and_return(applicable_task_names)
    end

    context "when the claim is not eligible for auto-approval" do
      let(:eligible?) { false }

      it "does not update the claim" do
        expect { auto_approve! }.not_to change { claim.reload }
      end

      it "does not create a decision" do
        expect { auto_approve! }.not_to change(Decision, :count)
      end

      it "does not create a note" do
        expect { auto_approve! }.not_to change(Note, :count)
      end

      it "does not send the approval email" do
        auto_approve!

        expect(ClaimMailer).not_to have_received(:approved).with(claim)
      end
    end

    context "when the claim is eligible for auto-approval" do
      let(:eligible?) { true }
      let(:expected_decision_attributes) do
        {
          approved: true,
          notes: "Auto-approved",
          created_by_id: nil
        }
      end
      let(:expected_note_attributes) do
        {
          created_by_id: nil,
          body: <<~TEXT
            This claim was auto-approved because it passed all automated checks
            (#{applicable_task_names.map(&:humanize).join(", ")})
          TEXT
        }
      end
      let(:expected_qa_note_attributes) do
        {
          body: "This claim has been marked for a quality assurance review",
          created_by_id: nil
        }
      end

      before do
        allow(claim).to receive(:flaggable_for_qa?).and_return(flaggable_for_qa?)
      end

      context "when the claim is selected for QA" do
        let(:flaggable_for_qa?) { true }

        it "creates an approval decision" do
          expect { auto_approve! }
            .to change(Decision, :count).by(1)
            .and change { claim.reload.latest_decision }.to(have_attributes(expected_decision_attributes))
        end

        it "creates one note for the auto-approval and one for the QA flagging" do
          expect { auto_approve! }
            .to change(Note, :count).by(2)
            .and change { claim.reload.notes.last(2).first }.to(have_attributes(expected_note_attributes))
            .and change { claim.reload.notes.last(2).last }.to(have_attributes(expected_qa_note_attributes))
        end

        it "does not send the approval email" do
          auto_approve!

          expect(ClaimMailer).not_to have_received(:approved).with(claim)
        end
      end

      context "when the claim is not selected for QA" do
        let(:flaggable_for_qa?) { false }

        it "creates an approval decision" do
          expect { auto_approve! }
            .to change(Decision, :count).by(1)
            .and change { claim.reload.latest_decision }.to(have_attributes(expected_decision_attributes))
        end

        it "creates a note" do
          expect { auto_approve! }
            .to change(Note, :count).by(1)
            .and change { claim.reload.notes.last }.to(have_attributes(expected_note_attributes))
        end

        it "sends the approval email" do
          auto_approve!

          expect(ClaimMailer).to have_received(:approved).with(claim)
        end
      end
    end

    context "when an error occurs while auto-approving" do
      let(:eligible?) { true }
      let(:expected_error) { described_class::AutoApprovalFailed }

      def suppress_exception
        yield
      rescue
        nil
      end

      before do
        allow(claim).to receive_message_chain(:notes, :create!) { raise(expected_error) }
      end

      it "raises the error" do
        expect { auto_approve! }.to raise_error(expected_error)
      end

      it "does not update the claim" do
        expect { suppress_exception { auto_approve! } }.not_to change { claim.reload }
      end

      it "does not create a decision" do
        expect { suppress_exception { auto_approve! } }.not_to change(Decision, :count)
      end

      it "does not create a note" do
        expect { suppress_exception { auto_approve! } }.not_to change(Note, :count)
      end

      it "does not send the approval email" do
        suppress_exception { auto_approve! }

        expect(ClaimMailer).not_to have_received(:approved).with(claim)
      end
    end
  end
end
