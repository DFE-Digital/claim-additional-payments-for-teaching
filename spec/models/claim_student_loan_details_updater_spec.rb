require "rails_helper"

RSpec.describe ClaimStudentLoanDetailsUpdater do
  let(:admin) { create(:dfe_signin_user) }

  describe ".call" do
    let(:updater) { described_class.new(claim, admin) }
    let(:claim) { create(:claim, policy:) }
    let(:policy) { Policies::StudentLoans }

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
    before { claim.reload }

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
            expect { described_class.new(claim, admin).update_claim_with_latest_data }
              .to not_change { claim.reload.has_student_loan }
              .and not_change { claim.student_loan_plan }
              .and not_change { claim.eligibility.student_loan_repayment_amount }
          end

          it "doesn't create an ammendment" do
            expect { described_class.new(claim, admin).update_claim_with_latest_data }
              .not_to change { claim.amendments.count }
          end
        end

        context "when the claim is not a tslr claim" do
          let(:policy_attributes) do
            {
              policy: Policies::FurtherEducationPayments
            }
          end

          it "doesn't change the claim attributes" do
            expect { described_class.new(claim, admin).update_claim_with_latest_data }
              .to not_change { claim.reload.has_student_loan }
              .and not_change { claim.student_loan_plan }
          end

          it "doesn't create an ammendment" do
            expect { described_class.new(claim, admin).update_claim_with_latest_data }
              .not_to change { claim.amendments.count }
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
            expect { described_class.new(claim, admin).update_claim_with_latest_data }
              .to change { claim.reload.has_student_loan }.from(nil).to(true)
              .and change { claim.student_loan_plan }.from(nil).to(StudentLoan::PLAN_1)
              .and change { claim.eligibility.student_loan_repayment_amount }.from(0).to(50)
          end

          it "creates an ammendment" do
            expect { described_class.new(claim, admin).update_claim_with_latest_data }
              .to change { claim.amendments.count }.by(1)

            amendment = claim.amendments.last

            expect(amendment.claim_changes).to eq({
              "has_student_loan" => [nil, true],
              "student_loan_plan" => [nil, StudentLoan::PLAN_1],
              "student_loan_repayment_amount" => [0, 50]
            })

            expect(amendment.notes).to eq(
              "Student loan details updated from SLC data"
            )

            expect(amendment.created_by).to eq(admin)
          end
        end

        context "when the claim is not a tslr claim" do
          let(:policy_attributes) do
            {
              policy: Policies::TargetedRetentionIncentivePayments
            }
          end

          it "updates the claim's attributes" do
            expect { described_class.new(claim, admin).update_claim_with_latest_data }
              .to change { claim.reload.has_student_loan }.from(nil).to(true)
              .and change { claim.student_loan_plan }.from(nil).to(StudentLoan::PLAN_1)
          end

          it "creates an ammendment" do
            expect { described_class.new(claim, admin).update_claim_with_latest_data }
              .to change { claim.amendments.count }.by(1)

            amendment = claim.amendments.last

            expect(amendment.claim_changes).to eq({
              "has_student_loan" => [nil, true],
              "student_loan_plan" => [nil, StudentLoan::PLAN_1]
            })

            expect(amendment.notes).to eq(
              "Student loan details updated from SLC data"
            )

            expect(amendment.created_by).to eq(admin)
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
            expect { described_class.new(claim, admin).update_claim_with_latest_data }
              .to not_change { claim.reload.has_student_loan }
              .and change { claim.student_loan_plan }.from(StudentLoan::PLAN_1).to(StudentLoan::PLAN_2)
              .and change { claim.eligibility.student_loan_repayment_amount }.from(50).to(100)
          end

          it "creates an ammendment" do
            expect { described_class.new(claim, admin).update_claim_with_latest_data }
              .to change { claim.amendments.count }.by(1)

            amendment = claim.amendments.last

            expect(amendment.claim_changes).to eq({
              "student_loan_plan" => [StudentLoan::PLAN_1, StudentLoan::PLAN_2],
              "student_loan_repayment_amount" => [50, 100]
            })

            expect(amendment.notes).to eq(
              "Student loan details updated from SLC data"
            )

            expect(amendment.created_by).to eq(admin)
          end
        end

        context "when the claim is not a tslr claim" do
          let(:policy_attributes) do
            {
              policy: Policies::FurtherEducationPayments
            }
          end

          it "replaces the student loan attributes with the latest values" do
            expect { described_class.new(claim, admin).update_claim_with_latest_data }
              .to not_change { claim.reload.has_student_loan }
              .and change { claim.student_loan_plan }.from(StudentLoan::PLAN_1).to(StudentLoan::PLAN_2)
          end

          it "creates an ammendment" do
            expect { described_class.new(claim, admin).update_claim_with_latest_data }
              .to change { claim.amendments.count }.by(1)

            amendment = claim.amendments.last

            expect(amendment.claim_changes).to eq({
              "student_loan_plan" => [StudentLoan::PLAN_1, StudentLoan::PLAN_2]
            })

            expect(amendment.notes).to eq(
              "Student loan details updated from SLC data"
            )

            expect(amendment.created_by).to eq(admin)
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
            expect { described_class.new(claim, admin).update_claim_with_latest_data }
              .to not_change { claim.reload.has_student_loan }
              .and change { claim.student_loan_plan }.from(StudentLoan::PLAN_1).to(StudentLoan::PLAN_1_AND_2)
              .and change { claim.eligibility.student_loan_repayment_amount }.from(50).to(300)
          end

          it "creates an ammendment" do
            expect { described_class.new(claim, admin).update_claim_with_latest_data }
              .to change { claim.amendments.count }.by(1)

            amendment = claim.amendments.last

            expect(amendment.claim_changes).to eq({
              "student_loan_plan" => [StudentLoan::PLAN_1, StudentLoan::PLAN_1_AND_2],
              "student_loan_repayment_amount" => [50, 300]
            })

            expect(amendment.notes).to eq(
              "Student loan details updated from SLC data"
            )

            expect(amendment.created_by).to eq(admin)
          end
        end

        context "when the claim is not a tslr claim" do
          let(:policy_attributes) do
            {
              policy: Policies::FurtherEducationPayments
            }
          end

          it "combines the data and replaces the existing claim attributes" do
            expect { described_class.new(claim, admin).update_claim_with_latest_data }
              .to not_change { claim.reload.has_student_loan }
              .and change { claim.student_loan_plan }.from(StudentLoan::PLAN_1).to(StudentLoan::PLAN_1_AND_2)
          end

          it "creates an ammendment" do
            expect { described_class.new(claim, admin).update_claim_with_latest_data }
              .to change { claim.amendments.count }.by(1)

            amendment = claim.amendments.last

            expect(amendment.claim_changes).to eq({
              "student_loan_plan" => [StudentLoan::PLAN_1, StudentLoan::PLAN_1_AND_2]
            })

            expect(amendment.notes).to eq(
              "Student loan details updated from SLC data"
            )

            expect(amendment.created_by).to eq(admin)
          end
        end
      end

      # This class should only be called with claims that are awaiting the
      # either the student_loan_plan or student_loan_amount task.
      # StudentLoans::Eligibility#student_loan_repayment_amount is validated
      # when an SLC claim is amended. This test is documenting the current
      # behaviour, we may want to do something else like return early if
      # attempting to amend the `student_loan_repayment_amount` from some
      # amount to £0.
      context "when no student loan data is found" do
        context "when the claim is a tslr claim" do
          let(:policy_attributes) do
            {
              policy: Policies::StudentLoans,
              eligibility_attributes: {student_loan_repayment_amount: 100}
            }
          end

          it "raises an error" do
            expect { described_class.new(claim, admin).update_claim_with_latest_data }
              .to raise_error(described_class::StudentLoanUpdateError).with_message(
                a_string_including(
                  "Eligibility student loan repayment amount Enter a positive amount up to £5,000.00"
                )
              )
              .and not_change { claim.reload.has_student_loan }
              .and not_change { claim.student_loan_plan }
              .and not_change { claim.eligibility.student_loan_repayment_amount }
          end
        end

        context "when the claim is not a tslr claim" do
          let(:policy_attributes) do
            {
              policy: Policies::EarlyYearsPayments
            }
          end

          it "resets the student loan attributes" do
            expect { described_class.new(claim, admin).update_claim_with_latest_data }
              .to change { claim.reload.has_student_loan }.from(true).to(nil)
              .and change { claim.student_loan_plan }.from(StudentLoan::PLAN_1).to(nil)
          end

          it "creates an ammendment" do
            expect { described_class.new(claim, admin).update_claim_with_latest_data }
              .to change { claim.amendments.count }.by(1)

            amendment = claim.amendments.last

            expect(amendment.claim_changes).to eq({
              "has_student_loan" => [true, nil],
              "student_loan_plan" => [StudentLoan::PLAN_1, nil]
            })

            expect(amendment.notes).to eq(
              "Student loan details updated from SLC data"
            )

            expect(amendment.created_by).to eq(admin)
          end
        end
      end
    end

    context "when creating the amendment fails" do
      before do
        create(
          :student_loans_data,
          nino: claim.national_insurance_number,
          date_of_birth: claim.date_of_birth,
          plan_type_of_deduction: 2,
          amount: 200
        )
      end

      let(:claim) do
        create(
          :claim,
          :submitted,
          has_student_loan: true,
          student_loan_plan: StudentLoan::PLAN_1,
          policy: Policies::StudentLoans,
          eligibility_attributes: {student_loan_repayment_amount: 50},
          personal_data_removed_at: DateTime.now # make the claim unaamendable
        )
      end

      it "raises an error and doesn't update the claim" do
        expect { described_class.new(claim, admin).update_claim_with_latest_data }
          .to raise_error(described_class::StudentLoanUpdateError).with_message(
            "Failed to update claim #{claim.id} student loan data. " \
            "amendment_error: \"Claim must be amendable\" " \
            "SLC data: {student_loan_plan: \"plan_2\", eligibility_attributes: {student_loan_repayment_amount: 200.0}}"
          )
      end
    end
  end
end
