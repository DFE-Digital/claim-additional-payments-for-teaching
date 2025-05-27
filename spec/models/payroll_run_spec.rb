require "rails_helper"

RSpec.describe PayrollRun, type: :model do
  before do
    create(:journey_configuration, :student_loans)
    create(:journey_configuration, :targeted_retention_incentive_payments)
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

  describe "#total_award_amount" do
    it "returns the sum of the award amounts of its claims" do
      payment_1 = build(:payment, claims: [build(:claim, :approved, eligibility_attributes: {award_amount: 1500})])
      payment_2 = build(:payment, claims: [build(:claim, :approved, eligibility_attributes: {award_amount: 2000})])

      payroll_run = PayrollRun.create!(created_by: user, payments: [payment_1, payment_2])

      expect(payroll_run.total_award_amount).to eq(3500)
    end
  end

  describe "#number_of_claims_for_policy" do
    it "returns the correct number of claims under each policy" do
      payment_1 = build(:payment, claims: [
        build(:claim, :approved, eligibility_attributes: {award_amount: 1500})
      ])
      payment_2 = build(:payment, claims: [
        build(:claim, :approved, policy: Policies::EarlyCareerPayments)
      ])
      payment_3 = build(:payment, claims: [
        build(:claim, :approved, policy: Policies::TargetedRetentionIncentivePayments)
      ])

      payroll_run = PayrollRun.create!(created_by: user, payments: [payment_1, payment_2, payment_3])

      expect(payroll_run.number_of_claims_for_policy(Policies::StudentLoans)).to eq(1)
      expect(payroll_run.number_of_claims_for_policy(Policies::EarlyCareerPayments)).to eq(1)
      expect(payroll_run.number_of_claims_for_policy(Policies::TargetedRetentionIncentivePayments)).to eq(1)
    end
  end

  describe "#total_claim_amount_for_policy" do
    it "returns the correct total amount claimed under each policy" do
      payment_1 = build(:payment, claims: [
        build(:claim, :approved, policy: Policies::StudentLoans, eligibility_attributes: {award_amount: 1500})
      ])
      payment_2 = build(:payment, claims: [
        build(:claim, :approved, policy: Policies::EarlyCareerPayments)
      ])
      payment_3 = build(:payment, claims: [
        build(:claim, :approved, policy: Policies::EarlyCareerPayments)
      ])
      payment_4 = build(:payment, claims: [
        build(:claim, :approved, eligibility_attributes: {award_amount: 1000})
      ])
      payment_5 = build(:payment, claims: [
        build(:claim, :approved, policy: Policies::TargetedRetentionIncentivePayments, bank_sort_code: "123456", bank_account_number: "12345678", national_insurance_number: "1234567"),
        build(:claim, :approved, bank_sort_code: "123456", bank_account_number: "12345678", national_insurance_number: "1234567", eligibility_attributes: {award_amount: 1000})
      ])

      payroll_run = PayrollRun.create!(created_by: user, payments: [payment_1, payment_2, payment_3, payment_4, payment_5])

      expect(payroll_run.total_claim_amount_for_policy(Policies::StudentLoans)).to eq(3500)
      expect(payroll_run.total_claim_amount_for_policy(Policies::EarlyCareerPayments)).to eq(10_000)
      expect(payroll_run.total_claim_amount_for_policy(Policies::TargetedRetentionIncentivePayments)).to eq(2000)
    end

    context "with topups" do
      it "returns the correct total accounting for top ups" do
        create(:targeted_retention_incentive_payments_award)

        topped_up_claim_1 = build(
          :claim,
          :approved,
          policy: Policies::TargetedRetentionIncentivePayments,
          bank_sort_code: "123456",
          bank_account_number: "12345678",
          national_insurance_number: "1234567",
          eligibility_attributes: {award_amount: 100}
        )

        topped_up_claim_2 = build(
          :claim,
          :approved,
          policy: Policies::TargetedRetentionIncentivePayments,
          bank_sort_code: "123456",
          bank_account_number: "12345678",
          national_insurance_number: "1234567",
          eligibility_attributes: {award_amount: 100}
        )

        non_topped_up_claim_1 = build(
          :claim,
          :approved,
          bank_sort_code: "123456",
          bank_account_number: "12345678",
          national_insurance_number: "1234567",
          policy: Policies::TargetedRetentionIncentivePayments,
          eligibility_attributes: {award_amount: 101}
        )

        non_topped_up_claim_2 = build(
          :claim,
          :approved,
          bank_sort_code: "123456",
          bank_account_number: "12345678",
          national_insurance_number: "1234567",
          policy: Policies::TargetedRetentionIncentivePayments,
          eligibility_attributes: {award_amount: 103}
        )

        targeted_retention_incentive_payment_1 = build(
          :payment,
          claims: [
            topped_up_claim_1
          ]
        )

        targeted_retention_incentive_payment_2 = build(
          :payment,
          claims: [
            topped_up_claim_2
          ]
        )

        targeted_retention_incentive_payment_3 = build(
          :payment,
          claims: [
            non_topped_up_claim_1
          ]
        )

        targeted_retention_incentive_payment_4 = build(
          :payment,
          claims: [
            non_topped_up_claim_2
          ]
        )

        payroll_run = PayrollRun.create!(
          created_by: user,
          payments: [
            targeted_retention_incentive_payment_1,
            targeted_retention_incentive_payment_2,
            targeted_retention_incentive_payment_3,
            targeted_retention_incentive_payment_4
          ]
        )

        create(
          :topup,
          claim: topped_up_claim_1,
          award_amount: 107,
          payment: targeted_retention_incentive_payment_1
        )

        create(
          :topup,
          claim: topped_up_claim_2,
          award_amount: 109,
          payment: targeted_retention_incentive_payment_2
        )

        expect(
          payroll_run.total_claim_amount_for_policy(
            Policies::TargetedRetentionIncentivePayments
          ).to_f
        ).to eq(420) # 101 + 103 + 107 + 109

        expect(
          payroll_run.total_claim_amount_for_policy(
            Policies::TargetedRetentionIncentivePayments,
            filter: :topups
          )
        ).to eq(216) # 107 + 109

        expect(
          payroll_run.total_claim_amount_for_policy(
            Policies::TargetedRetentionIncentivePayments,
            filter: :claims
          )
        ).to eq(204) # 103 + 101
      end
    end

    it "handles claims that have topups in multiple payroll runs" do
      claim_1 = create(
        :claim,
        :approved,
        policy: Policies::EarlyCareerPayments,
        eligibility_attributes: {
          award_amount: 1
        }
      )

      claim_2 = create(
        :claim,
        :approved,
        policy: Policies::EarlyCareerPayments,
        eligibility_attributes: {
          award_amount: 7
        },
        date_of_birth: claim_1.date_of_birth,
        student_loan_plan: claim_1.student_loan_plan,
        bank_sort_code: claim_1.bank_sort_code,
        bank_account_number: claim_1.bank_account_number,
        building_society_roll_number: claim_1.building_society_roll_number,
        national_insurance_number: claim_1.national_insurance_number
      )

      first_payroll_run = nil

      travel_to 2.month.ago do
        first_payroll_run = create(:payroll_run)

        create(
          :payment,
          claims: [claim_1],
          payroll_run: first_payroll_run
        )
      end

      second_payroll_run = nil

      travel_to 1.month.ago do
        second_payroll_run = create(:payroll_run)

        create(
          :payment,
          claims: [claim_1, claim_2],
          topups: [create(:topup, claim: claim_1, award_amount: 3)],
          payroll_run: second_payroll_run
        )
      end

      third_payroll_run = create(:payroll_run)

      create(
        :payment,
        claims: [claim_1],
        topups: [create(:topup, claim: claim_1, award_amount: 5)],
        payroll_run: third_payroll_run
      )

      expect(
        first_payroll_run.total_claim_amount_for_policy(Policies::EarlyCareerPayments)
      ).to eq(1)

      expect(
        first_payroll_run.total_claim_amount_for_policy(Policies::EarlyCareerPayments, filter: :claims)
      ).to eq(1)

      expect(
        first_payroll_run.total_claim_amount_for_policy(Policies::EarlyCareerPayments, filter: :topups)
      ).to eq(0)

      expect(
        first_payroll_run.number_of_claims_for_policy(Policies::EarlyCareerPayments)
      ).to eq(1)

      expect(
        first_payroll_run.number_of_claims_for_policy(Policies::EarlyCareerPayments, filter: :claims)
      ).to eq(1)

      expect(
        first_payroll_run.number_of_claims_for_policy(Policies::EarlyCareerPayments, filter: :topups)
      ).to eq(0)

      expect(
        second_payroll_run.total_claim_amount_for_policy(Policies::EarlyCareerPayments)
      ).to eq(10) # topup 3 + claim 7

      expect(
        second_payroll_run.total_claim_amount_for_policy(Policies::EarlyCareerPayments, filter: :claims)
      ).to eq(7)

      expect(
        second_payroll_run.total_claim_amount_for_policy(Policies::EarlyCareerPayments, filter: :topups)
      ).to eq(3)

      expect(
        second_payroll_run.number_of_claims_for_policy(Policies::EarlyCareerPayments)
      ).to eq(2) # topup for claim 1 + claim 2

      expect(
        second_payroll_run.number_of_claims_for_policy(Policies::EarlyCareerPayments, filter: :claims)
      ).to eq(1)

      expect(
        second_payroll_run.number_of_claims_for_policy(Policies::EarlyCareerPayments, filter: :topups)
      ).to eq(1)

      expect(
        third_payroll_run.total_claim_amount_for_policy(Policies::EarlyCareerPayments)
      ).to eq(5)

      expect(
        third_payroll_run.total_claim_amount_for_policy(Policies::EarlyCareerPayments, filter: :claims)
      ).to eq(0)

      expect(
        third_payroll_run.total_claim_amount_for_policy(Policies::EarlyCareerPayments, filter: :topups)
      ).to eq(5)

      expect(
        third_payroll_run.number_of_claims_for_policy(Policies::EarlyCareerPayments)
      ).to eq(1)

      expect(
        third_payroll_run.number_of_claims_for_policy(Policies::EarlyCareerPayments, filter: :claims)
      ).to eq(0)

      expect(
        third_payroll_run.number_of_claims_for_policy(Policies::EarlyCareerPayments, filter: :topups)
      ).to eq(1)
    end
  end

  describe ".this_month" do
    it "only includes payroll runs created in this calendar month" do
      create(:payroll_run, created_at: 1.month.ago)
      created_this_month = create(:payroll_run, created_at: 5.minutes.ago)

      expect(PayrollRun.this_month).to eq([created_this_month])
    end
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
