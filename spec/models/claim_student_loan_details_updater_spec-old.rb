require "rails_helper"

RSpec.describe ClaimStudentLoanDetailsUpdater do
  let(:updater) { described_class.new(claim, admin) }
  let(:claim) { create(:claim, policy:) }
  let(:policy) { Policies::StudentLoans }
  let(:admin) { create(:dfe_signin_user) }

  describe ".call" do
    let(:updater_mock) { instance_double(described_class) }

    before do
      allow(described_class).to receive(:new).with(claim, admin).and_return(updater_mock)
    end

    it "invokes the `update_claim_with_latest_data` instance method" do
      expect(updater_mock).to receive(:update_claim_with_latest_data)
      described_class.call(claim, admin)
    end
  end

  describe "#update_claim_with_latest_data" do
    subject(:call) { updater.update_claim_with_latest_data }

    context "when no existing SLC data is found for the claimant" do
      it "returns true" do
        expect(call).to eq(true)
      end

      context "when the policy is StudentLoans" do
        let(:policy) { Policies::StudentLoans }

        it "does not update the claim student plan and zero repayment total" do
          expect { call }.not_to change { claim.reload.has_student_loan }
        end

        it "keeps the `submitted_using_slc_data` flag to `false` (default)" do
          expect { call }.not_to change { claim.submitted_using_slc_data }.from(false)
        end

        it "does not create an amendment" do
          expect { call }.not_to change { claim.amendments.count }
        end
      end

      [Policies::EarlyCareerPayments, Policies::LevellingUpPremiumPayments, Policies::FurtherEducationPayments].each do |policy|
        context "when the policy is #{policy}" do
          let(:policy) { policy }

          it "does not update the claim" do
            expect { call }.not_to change { claim.reload }
          end

          it "does not create an amendment" do
            expect { call }.not_to change { claim.amendments.count }
          end
        end
      end
    end

    context "when SLC data is found with student loan information for the claimant" do
      before do
        create(:student_loans_data, nino: claim.national_insurance_number, date_of_birth: claim.date_of_birth, plan_type_of_deduction: 1, amount: 50)
        create(:student_loans_data, nino: claim.national_insurance_number, date_of_birth: claim.date_of_birth, plan_type_of_deduction: 2, amount: 60)
      end

      it "returns true" do
        expect(call).to eq(true)
      end

      context "when the policy is StudentLoans" do
        it "updates the claim with the student plan and the repayment total" do
          expect { call }.to change { claim.reload.has_student_loan }.to(true)
            .and change { claim.student_loan_plan }.to(StudentLoan::PLAN_1_AND_2)
            .and change { claim.eligibility.student_loan_repayment_amount }.to(110)
        end

        it "creates an amendment" do
          expect { call }.to change { claim.amendments.count }.by(1)

          amendment = claim.amendments.last

          expect(amendment.claim_changes).to eq({
            "has_student_loan" => [false, true],
            "student_loan_plan" => [Claim::NO_STUDENT_LOAN, StudentLoan::PLAN_1_AND_2],
            "student_loan_repayment_amount" => [0, 110]
          })

          expect(amendment.notes).to eq(
            "Student loan details updated from SLC data"
          )

          expect(amendment.created_by).to eq(admin)
        end
      end

      [Policies::EarlyCareerPayments, Policies::LevellingUpPremiumPayments, Policies::FurtherEducationPayments].each do |policy|
        context "when the policy is #{policy}" do
          let(:policy) { policy }

          it "updates the claim with the student plan only" do
            expect { call }.to change { claim.reload.has_student_loan }.to(true)
              .and change { claim.student_loan_plan }.to(StudentLoan::PLAN_1_AND_2)
          end

          it "creates an amendment" do
            expect { call }.to change { claim.amendments.count }.by(1)

            amendment = claim.amendments.last

            expect(amendment.claim_changes).to eq({
              "has_student_loan" => [false, true],
              "student_loan_plan" => [Claim::NO_STUDENT_LOAN, StudentLoan::PLAN_1_AND_2]
            })

            expect(amendment.notes).to eq(
              "Student loan details updated from SLC data"
            )

            expect(amendment.created_by).to eq(admin)
          end
        end
      end
    end

    context "when SLC data is found with no student loan information for the claimant" do
      before do
        create(:student_loans_data, nino: claim.national_insurance_number, date_of_birth: claim.date_of_birth, plan_type_of_deduction: nil, amount: nil)
      end

      it "returns true" do
        expect(call).to eq(true)
      end

      context "when the policy is StudentLoans" do
        it "updates the claim with the student plan and the repayment total" do
          expect { call }.to change { claim.reload.has_student_loan }.to(false)
            .and change { claim.student_loan_plan }.to(Claim::NO_STUDENT_LOAN)
            .and change { claim.eligibility.student_loan_repayment_amount }.to(0)
        end

        it "creates an amendment with the student plan change" do
          expect { call }.to change { claim.amendments.count }.by(1)

          amendment = claim.amendments.last

          expect(amendment.claim_changes).to eq({
            "has_student_loan" => [true, false],
            "student_loan_plan" => [StudentLoan::PLAN_1_AND_2, Claim::NO_STUDENT_LOAN],
            "student_loan_repayment_amount" => [110, 0]
          })

          expect(amendment.notes).to eq(
            "Student loan details updated from SLC data"
          )

          expect(amendment.created_by).to eq(admin)
        end
      end

      [Policies::EarlyCareerPayments, Policies::LevellingUpPremiumPayments].each do |policy|
        context "when the policy is #{policy}" do
          let(:policy) { policy }

          it "updates the claim with the student plan only" do
            expect { call }.to change { claim.reload.has_student_loan }.to(false)
              .and change { claim.student_loan_plan }.to(Claim::NO_STUDENT_LOAN)
          end

          it "creates an amendment with the student plan change" do
            expect { call }.to change { claim.amendments.count }.by(1)

            amendment = claim.amendments.last

            expect(amendment.claim_changes).to eq({
              "has_student_loan" => [true, false],
              "student_loan_plan" => [StudentLoan::PLAN_1_AND_2, Claim::NO_STUDENT_LOAN]
            })

            expect(amendment.notes).to eq(
              "Student loan details updated from SLC data"
            )

            expect(amendment.created_by).to eq(admin)
          end
        end
      end
    end

    context "when updating a claim after submission" do
      let(:claim) do
        create(
          :claim,
          :submitted,
          :with_no_student_loan,
          policy:,
          eligibility_attributes: {
            student_loan_repayment_amount: 0
          }
        )
      end

      before do
        create(:student_loans_data, nino: claim.national_insurance_number, date_of_birth: claim.date_of_birth, plan_type_of_deduction: 1, amount: 50)
      end

      it "updates the claim with the student plan and the repayment total" do
        expect { call }.to change { claim.reload.has_student_loan }.to(true)
          .and change { claim.student_loan_plan }.to(StudentLoan::PLAN_1)
          .and change { claim.eligibility.student_loan_repayment_amount }.to(50)
      end

      it "creates an amendment" do
        expect { call }.to change { claim.amendments.count }.by(1)

        amendment = claim.amendments.last

        expect(amendment.claim_changes).to eq({
          "has_student_loan" => [false, true],
          "student_loan_plan" => [nil, StudentLoan::PLAN_1],
          "student_loan_repayment_amount" => [0, 50]
        })

        expect(amendment.notes).to eq(
          "Student loan details updated from SLC data"
        )

        expect(amendment.created_by).to eq(admin)
      end

      it "does not change the `submitted_using_slc_data` flag" do
        expect { call }.to not_change { claim.submitted_using_slc_data }
      end
    end
  end
end
