require "rails_helper"

RSpec.describe PayrollRun, type: :model do
  before do
    create(:journey_configuration, :student_loans)
    create(:journey_configuration, :additional_payments)
  end

  let(:user) { create(:dfe_signin_user) }

  it "cannot be created when another PayrollRun has occurred in same month" do
    create(:payroll_run)
    another_payroll_run = build(:payroll_run)

    expect(another_payroll_run.valid?).to be false
    expect { another_payroll_run.save! }.to raise_error(ActiveRecord::RecordInvalid)

    travel_to Time.zone.now.next_month do
      next_month_payroll_run = build(:payroll_run)

      expect(next_month_payroll_run.valid?).to be true
      expect { next_month_payroll_run.save! }.not_to raise_error
    end
  end

  context "validating the number of payments entering payroll" do
    let(:stubbed_max_payments) { 10 }
    let(:payroll_run) { build(:payroll_run, :with_payments, count: payments_count) }

    before do
      stub_const("PayrollRun::MAX_MONTHLY_PAYMENTS", stubbed_max_payments)
    end

    context "when exceeding the number of maximum allowed payments" do
      let(:payments_count) { stubbed_max_payments + 1 }

      it "returns a validation error", :aggregate_failures do
        expect(payroll_run.valid?).to eq(false)
        expect(payroll_run.errors[:base]).to eq(["This payroll run exceeds #{stubbed_max_payments} payments"])
        expect { payroll_run.save! }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "when not exceeding the number of maximum allowed payments" do
      let(:payments_count) { stubbed_max_payments }

      it "creates the payroll run", :aggregate_failures do
        expect(payroll_run.valid?).to eq(true)
        expect(payroll_run.errors[:base]).to be_empty
        expect { payroll_run.save! }.to change { payroll_run.persisted? }.to(true)
      end
    end
  end

  describe "#total_award_amount" do
    it "returns the sum of the award amounts of its claims" do
      payment_1 = build(:payment, claims: [build(:claim, :approved, eligibility_attributes: {student_loan_repayment_amount: 1500})])
      payment_2 = build(:payment, claims: [build(:claim, :approved, eligibility_attributes: {student_loan_repayment_amount: 2000})])

      payroll_run = PayrollRun.create!(created_by: user, payments: [payment_1, payment_2])

      expect(payroll_run.total_award_amount).to eq(3500)
    end
  end

  describe "#number_of_claims_for_policy" do
    it "returns the correct number of claims under each policy" do
      payment_1 = build(:payment, claims: [
        build(:claim, :approved, eligibility_attributes: {student_loan_repayment_amount: 1500})
      ])
      payment_2 = build(:payment, claims: [
        build(:claim, :approved, policy: Policies::EarlyCareerPayments)
      ])
      payment_3 = build(:payment, claims: [
        build(:claim, :approved, policy: Policies::LevellingUpPremiumPayments)
      ])

      payroll_run = PayrollRun.create!(created_by: user, payments: [payment_1, payment_2, payment_3])

      expect(payroll_run.number_of_claims_for_policy(Policies::StudentLoans)).to eq(1)
      expect(payroll_run.number_of_claims_for_policy(Policies::EarlyCareerPayments)).to eq(1)
      expect(payroll_run.number_of_claims_for_policy(Policies::LevellingUpPremiumPayments)).to eq(1)
    end
  end

  describe "#total_claim_amount_for_policy" do
    it "returns the correct total amount claimed under each policy" do
      payment_1 = build(:payment, claims: [
        build(:claim, :approved, policy: Policies::StudentLoans, eligibility_attributes: {student_loan_repayment_amount: 1500})
      ])
      payment_2 = build(:payment, claims: [
        build(:claim, :approved, policy: Policies::EarlyCareerPayments)
      ])
      payment_3 = build(:payment, claims: [
        build(:claim, :approved, policy: Policies::EarlyCareerPayments)
      ])
      payment_4 = build(:payment, claims: [
        build(:claim, :approved, eligibility_attributes: {student_loan_repayment_amount: 1000})
      ])
      payment_5 = build(:payment, claims: [
        build(:claim, :approved, policy: Policies::LevellingUpPremiumPayments, bank_sort_code: "123456", bank_account_number: "12345678", national_insurance_number: "1234567"),
        build(:claim, :approved, bank_sort_code: "123456", bank_account_number: "12345678", national_insurance_number: "1234567", eligibility_attributes: {student_loan_repayment_amount: 1000})
      ])

      payroll_run = PayrollRun.create!(created_by: user, payments: [payment_1, payment_2, payment_3, payment_4, payment_5])

      expect(payroll_run.total_claim_amount_for_policy(Policies::StudentLoans)).to eq(3500)
      expect(payroll_run.total_claim_amount_for_policy(Policies::EarlyCareerPayments)).to eq(10_000)
      expect(payroll_run.total_claim_amount_for_policy(Policies::LevellingUpPremiumPayments)).to eq(2000)
    end
  end

  describe ".create_with_claims!" do
    let(:claims) { Policies.all.map { |policy| create(:claim, :approved, policy: policy) } }
    let(:topups) { [] }
    subject!(:payroll_run) { PayrollRun.create_with_claims!(claims, topups, created_by: user) }

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

  describe ".this_month" do
    it "only includes payroll runs created in this calendar month" do
      create(:payroll_run, created_at: 1.month.ago)
      created_this_month = create(:payroll_run, created_at: 5.minutes.ago)

      expect(PayrollRun.this_month).to eq([created_this_month])
    end
  end

  describe "#total_batches" do
    subject(:total) { payroll_run.total_batches }

    let(:payroll_run) { create(:payroll_run, claims_counts: {Policies::StudentLoans => 5}) }
    let(:batch_size) { 2 }

    before do
      stub_const("#{described_class}::MAX_BATCH_SIZE", batch_size)
    end

    it { is_expected.to eq(3) }
  end

  describe "#total_confirmed_payments" do
    subject(:total) { payroll_run.total_confirmed_payments }

    let(:payroll_run) do
      create(:payroll_run, :with_confirmations, confirmed_batches: 2, claims_counts: {
        Policies::StudentLoans => 5
      })
    end
    let(:batch_size) { 2 }

    before do
      stub_const("#{described_class}::MAX_BATCH_SIZE", batch_size)
    end

    it { is_expected.to eq(4) }
  end

  describe "#all_payments_confirmed?" do
    subject { payroll_run.all_payments_confirmed? }

    let(:payroll_run) do
      create(:payroll_run,
        :with_confirmations,
        confirmed_batches: confirmed_batches,
        claims_counts: {Policies::StudentLoans => 5})
    end
    let(:batch_size) { 2 }

    before do
      stub_const("#{described_class}::MAX_BATCH_SIZE", batch_size)
    end

    context "when some payments have not been confirmed" do
      let(:confirmed_batches) { 2 }

      it { is_expected.to eq(false) }
    end

    context "when all payments have been confirmed" do
      let(:confirmed_batches) { 3 }

      it { is_expected.to eq(true) }
    end
  end

  describe "#download_triggered?" do
    it "returns true when downloaded_at and downloaded_by are present" do
      payroll_run = create(:payroll_run)

      expect(payroll_run.download_triggered?).to eql false

      payroll_run.update!(downloaded_at: Time.zone.now, downloaded_by: user)

      expect(payroll_run.download_triggered?).to eql true
    end
  end
end
