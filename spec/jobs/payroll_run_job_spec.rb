require "rails_helper"

RSpec.describe PayrollRunJob, type: :job do
  let(:user) { create(:dfe_signin_user) }
  let(:payroll_run) { create(:payroll_run, created_by: user) }

  describe "#perform" do
    context "when successful" do
      let(:claims) { Policies.all.map { |policy| create(:claim, :approved, policy: policy) } }
      let(:topups) { [] }

      before do
        described_class.perform_now(payroll_run, claims.map(&:id), topups.map(&:id))
      end

      it "creates a payroll run with payments and populates the award_amount" do
        expect(payroll_run.reload.created_by.id).to eq(user.id)
        expect(payroll_run.claims).to match_array(claims)
        expect(claims[0].payments.first.award_amount).to eq(claims[0].award_amount)
        expect(claims[1].payments.first.award_amount).to eq(claims[1].award_amount)
      end

      context "with multiple claims from the same teacher reference number" do
        let(:personal_details) do
          {
            national_insurance_number: generate(:national_insurance_number),
            eligibility_attributes: {teacher_reference_number: generate(:teacher_reference_number)},
            email_address: generate(:email_address),
            bank_sort_code: "112233",
            bank_account_number: "95928482",
            address_line_1: "64 West Lane",
            student_loan_plan: StudentLoan::PLAN_1
          }
        end
        let(:matching_claims) do
          [
            create(:claim, :approved, personal_details.merge(policy: Policies::StudentLoans)),
            create(:claim, :approved, personal_details.merge(policy: Policies::EarlyCareerPayments))
          ]
        end
        let(:other_claim) { create(:claim, :approved) }
        let(:claims) { matching_claims + [other_claim] }

        it "groups them into a single payment and populates the award_amount" do
          expect(payroll_run.payments.map(&:claims)).to match_array([match_array(matching_claims), [other_claim]])
          expect(matching_claims[0].reload.payments.first.award_amount).to eq(matching_claims.sum(&:award_amount))
        end
      end
    end

    context "when errored" do
      before do
        allow(Payment).to receive(:create!).and_raise(StandardError)
      end

      it "marks the payroll run as failed and reraises the error" do
        expect do
          described_class.perform_now(payroll_run, [create(:claim).id], [])
        end.to raise_error(StandardError)

        expect(payroll_run.reload.failed?).to be true
      end
    end
  end
end
