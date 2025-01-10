require "rails_helper"

RSpec.describe ClaimStudentLoanDetailsUpdater do
  describe ".call" do
    let(:updater) { described_class.new(claim) }
    let(:claim) { create(:claim, policy:) }
    let(:policy) { Policies::StudentLoans }

    let(:updater_mock) { instance_double(described_class) }

    before do
      allow(described_class).to receive(:new).with(claim).and_return(updater_mock)
    end

    it "invokes the `update_claim_with_latest_data` instance method" do
      expect(updater_mock).to receive(:update_claim_with_latest_data)
      described_class.call(claim)
    end
  end

  describe "#update_claim_with_latest_data" do
    context "when the claim has no student loan data" do
      let(:claim) do
        create(
          :claim,
          :submitted,
          has_student_loan: nil,
          student_loan_plan: nil,
          **policy_attributes
        )
      end

      context "when no student loan data is found" do
        context "when the claim is a tslr claim" do
          let(:policy_attributes) do
            {
              policy: Policies::StudentLoans,
              eligibility_attributes: {student_loan_repayment_amount: 0}
            }
          end

          it "doesn't change the claim attributes" do
            expect { described_class.new(claim).update_claim_with_latest_data }
              .to not_change { claim.reload.has_student_loan }
              .and not_change { claim.student_loan_plan }
              .and not_change { claim.eligibility.student_loan_repayment_amount }
          end
        end

        context "when the claim is not a tslr claim" do
          let(:policy_attributes) do
            {
              policy: Policies::FurtherEducationPayments
            }
          end

          it "doesn't change the claim attributes" do
            expect { described_class.new(claim).update_claim_with_latest_data }
              .to not_change { claim.reload.has_student_loan }
              .and not_change { claim.student_loan_plan }
          end
        end
      end

      context "when student loan data is found" do
        before do
          create(
            :student_loans_data,
            nino: claim.national_insurance_number,
            date_of_birth: claim.date_of_birth,
            plan_type_of_deduction: 1,
            amount: 50
          )
        end

        context "when the claim is a tslr claim" do
          let(:policy_attributes) do
            {
              policy: Policies::StudentLoans,
              eligibility_attributes: {student_loan_repayment_amount: 0}
            }
          end

          it "updates the claim's attributes" do
            expect { described_class.new(claim).update_claim_with_latest_data }
              .to change { claim.reload.has_student_loan }.from(nil).to(true)
              .and change { claim.student_loan_plan }.from(nil).to(StudentLoan::PLAN_1)
              .and change { claim.eligibility.student_loan_repayment_amount }.from(0).to(50)
          end
        end

        context "when the claim is not a tslr claim" do
          let(:policy_attributes) do
            {
              policy: Policies::LevellingUpPremiumPayments
            }
          end

          it "updates the claim's attributes" do
            expect { described_class.new(claim).update_claim_with_latest_data }
              .to change { claim.reload.has_student_loan }.from(nil).to(true)
              .and change { claim.student_loan_plan }.from(nil).to(StudentLoan::PLAN_1)
          end
        end
      end
    end

    context "when the claim has student loan data" do
      let(:claim) do
        create(
          :claim,
          :submitted,
          has_student_loan: true,
          student_loan_plan: StudentLoan::PLAN_1,
          **policy_attributes
        )
      end

      context "when no student loan data is found" do
        context "when the claim is a tslr claim" do
          let(:policy_attributes) do
            {
              policy: Policies::StudentLoans,
              eligibility_attributes: {student_loan_repayment_amount: 100}
            }
          end

          it "resets the student loan attributes" do
            expect { described_class.new(claim).update_claim_with_latest_data }
              .to change { claim.reload.has_student_loan }.from(true).to(nil)
              .and change { claim.student_loan_plan }.from(StudentLoan::PLAN_1).to(nil)
              .and change { claim.eligibility.student_loan_repayment_amount }.from(100).to(0)
          end
        end

        context "when the claim is not a tslr claim" do
          let(:policy_attributes) do
            {
              policy: Policies::EarlyYearsPayments
            }
          end

          it "resets the student loan attributes" do
            expect { described_class.new(claim).update_claim_with_latest_data }
              .to change { claim.reload.has_student_loan }.from(true).to(nil)
              .and change { claim.student_loan_plan }.from(StudentLoan::PLAN_1).to(nil)
          end
        end
      end

      context "when student loan data is found" do
        before do
          create(
            :student_loans_data,
            nino: claim.national_insurance_number,
            date_of_birth: claim.date_of_birth,
            plan_type_of_deduction: 2,
            amount: 100
          )
        end

        context "when the claim is a tslr claim" do
          let(:policy_attributes) do
            {
              policy: Policies::StudentLoans,
              eligibility_attributes: {student_loan_repayment_amount: 50}
            }
          end

          it "replaces the student loan attributes with the latest values" do
            expect { described_class.new(claim).update_claim_with_latest_data }
              .to not_change { claim.reload.has_student_loan }
              .and change { claim.student_loan_plan }.from(StudentLoan::PLAN_1).to(StudentLoan::PLAN_2)
              .and change { claim.eligibility.student_loan_repayment_amount }.from(50).to(300)
          end
        end

        context "when the claim is not a tslr claim" do
          let(:policy_attributes) do
            {
              policy: Policies::FurtherEducationPayments
            }
          end

          it "replaces the student loan attributes with the latest values" do
            expect { described_class.new(claim).update_claim_with_latest_data }
              .to not_change { claim.reload.has_student_loan }
              .and change { claim.student_loan_plan }.from(StudentLoan::PLAN_1).to(StudentLoan::PLAN_2)
          end
        end
      end

      context "when multiple student loan data is found" do
        before do
          create(
            :student_loans_data,
            nino: claim.national_insurance_number,
            date_of_birth: claim.date_of_birth,
            plan_type_of_deduction: 1,
            amount: 100
          )

          create(
            :student_loans_data,
            nino: claim.national_insurance_number,
            date_of_birth: claim.date_of_birth,
            plan_type_of_deduction: 2,
            amount: 200
          )
        end

        context "when the claim is a tslr claim" do
          let(:policy_attributes) do
            {
              policy: Policies::StudentLoans,
              eligibility_attributes: {student_loan_repayment_amount: 50}
            }
          end

          it "combines the data and replaces the existing claim attributes" do
            expect { described_class.new(claim).update_claim_with_latest_data }
              .to not_change { claim.reload.has_student_loan }
              .and change { claim.student_loan_plan }.from(StudentLoan::PLAN_1).to(StudentLoan::PLAN_1_AND_2)
              .and change { claim.eligibility.student_loan_repayment_amount }.from(50).to(300)
          end
        end

        context "when the claim is not a tslr claim" do
          it "combines the data and replaces the existing claim attributes" do
            expect { described_class.new(claim).update_claim_with_latest_data }
              .to not_change { claim.reload.has_student_loan }
              .and change { claim.student_loan_plan }.from(StudentLoan::PLAN_1).to(StudentLoan::PLAN_1_AND_2)
          end
        end
      end
    end
  end
end
