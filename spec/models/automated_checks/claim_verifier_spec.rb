require "rails_helper"

RSpec.describe AutomatedChecks::ClaimVerifier do
  subject(:claim_verifier) { described_class.new(**claim_verifier_args) }

  describe "#perform" do
    subject(:perform) { claim_verifier.perform }

    context "when the verifiers argument is present" do
      context "with two successful verifications" do
        let(:claim_verifier_args) do
          {
            claim: nil,
            dqt_teacher_status: nil,
            verifiers: [
              double("first verifier", perform: nil),
              double("second verifier", perform: Task.new),
              double("third verifier", perform: Task.new),
              double("third verifier", perform: Object.new)
            ]
          }
        end

        it { is_expected.to eq(2) }

        it "performs verifications" do
          perform

          claim_verifier_args[:verifiers].each do |verifier|
            expect(verifier).to have_received(:perform)
          end
        end
      end
    end

    context "when the verifiers argument is not present" do
      let(:claim) { create(:claim) }
      let(:admin_user) { create(:dfe_signin_user) }
      let(:dqt_teacher_status) { {"test" => "test"} }

      let(:claim_verifier_args) do
        {
          claim: claim,
          dqt_teacher_status: dqt_teacher_status,
          admin_user: admin_user
        }
      end

      context "when the Claim#policy VERIFIERS is present" do
        let(:verifiers) do
          [
            double(perform: Task.new),
            double(perform: Task.new),
            double(perform: Task.new),
            double(perform: Object.new),
            double(perform: nil),
            double(perform: nil)
          ]
        end

        before do
          claim.policy::VERIFIERS.each_with_index do |verifier, index|
            allow(verifier).to receive(:new).and_return(verifiers[index])
          end
        end

        it { is_expected.to eq(3) }

        it "performs verifications based on the Policy::VERIFIERS" do
          perform

          expect(AutomatedChecks::ClaimVerifiers::Identity).to have_received(:new).with(
            claim:,
            dqt_teacher_status:,
            admin_user:
          )

          expect(AutomatedChecks::ClaimVerifiers::Qualifications).to have_received(:new).with(
            claim:,
            dqt_teacher_status:,
            admin_user:
          )

          expect(AutomatedChecks::ClaimVerifiers::CensusSubjectsTaught).to have_received(:new).with(
            claim:,
            admin_user:
          )

          expect(AutomatedChecks::ClaimVerifiers::Employment).to have_received(:new).with(
            claim:,
            admin_user:
          )

          expect(AutomatedChecks::ClaimVerifiers::StudentLoanAmount).to have_received(:new).with(
            claim:,
            admin_user:
          )

          verifiers.each do |verifier|
            expect(verifier).to have_received(:perform)
          end
        end
      end

      context "when the Claim#policy VERIFIERS is not present" do
        let(:mock_policy) { Class.new }

        before do
          allow(claim).to receive(:policy).and_return(mock_policy)
        end

        it { is_expected.to eq(0) }
      end
    end

    context "when verifier is conditional" do
      subject(:perform) { claim_verifier }

      let(:claim) { create(:claim, policy: Policies::FurtherEducationPayments) }

      let(:claim_verifier_args) do
        {
          claim:,
          dqt_teacher_status: nil
        }
      end

      context "and is needed" do
        before do
          claim.eligibility.update teacher_reference_number: "1234567"
        end

        it "creates relevant task" do
          expect {
            subject.perform
          }.to change { Task.where(name: "employment").count }.by(1)
        end
      end

      context "and is not needed" do
        before do
          claim.eligibility.update teacher_reference_number: nil
        end

        it "does not create relevant task" do
          expect {
            subject.perform
          }.to change { Task.where(name: "employment").count }.by(0)
        end
      end
    end
  end
end
