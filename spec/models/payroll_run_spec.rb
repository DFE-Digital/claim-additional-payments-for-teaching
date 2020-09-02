require "rails_helper"

RSpec.describe PayrollRun, type: :model do
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

  it "can be updated in the same month as it was created" do
    payroll_run = create(:payroll_run)
    confirmation_report_uploaded_time = Time.zone.now.end_of_month
    service_operator = build(:dfe_signin_user)

    travel_to confirmation_report_uploaded_time do
      payroll_run.confirmation_report_uploaded_by = service_operator

      expect(payroll_run.save!).to be true
      expect(payroll_run.confirmation_report_uploaded_by).eql? service_operator
    end
  end

  describe "#total_award_amount" do
    it "returns the sum of the award amounts of its claims" do
      payment_1 = build(:payment, claims: [build(:claim, :approved, eligibility: build(:student_loans_eligibility, :eligible, student_loan_repayment_amount: 1500))])
      payment_2 = build(:payment, claims: [build(:claim, :approved, eligibility: build(:student_loans_eligibility, :eligible, student_loan_repayment_amount: 2000))])

      payroll_run = PayrollRun.create!(created_by: user, payments: [payment_1, payment_2])

      expect(payroll_run.total_award_amount).to eq(3500)
    end
  end

  describe "#number_of_claims_for_policy" do
    it "returns the correct number of claims under each policy" do
      payment_1 = build(:payment, claims: [
        build(:claim, :approved, eligibility: build(:student_loans_eligibility, :eligible, student_loan_repayment_amount: 1500))
      ])
      payment_2 = build(:payment, claims: [
        build(:claim, :approved, eligibility: build(:maths_and_physics_eligibility, :eligible))
      ])
      payment_3 = build(:payment, claims: [
        build(:claim, :approved, eligibility: build(:maths_and_physics_eligibility, :eligible))
      ])

      payroll_run = PayrollRun.create!(created_by: user, payments: [payment_1, payment_2, payment_3])

      expect(payroll_run.number_of_claims_for_policy(StudentLoans)).to eq(1)
      expect(payroll_run.number_of_claims_for_policy(MathsAndPhysics)).to eq(2)
    end
  end

  describe "#total_claim_amount_for_policy" do
    it "returns the correct total amount claimed under each policy" do
      payment_1 = build(:payment, claims: [
        build(:claim, :approved, eligibility: build(:student_loans_eligibility, :eligible, student_loan_repayment_amount: 1500))
      ])
      payment_2 = build(:payment, claims: [
        build(:claim, :approved, eligibility: build(:maths_and_physics_eligibility, :eligible))
      ])
      payment_3 = build(:payment, claims: [
        build(:claim, :approved, eligibility: build(:maths_and_physics_eligibility, :eligible))
      ])
      payment_4 = build(:payment, claims: [
        build(:claim, :approved, eligibility: build(:student_loans_eligibility, :eligible, student_loan_repayment_amount: 1000))
      ])

      payroll_run = PayrollRun.create!(created_by: user, payments: [payment_1, payment_2, payment_3, payment_4])

      expect(payroll_run.total_claim_amount_for_policy(StudentLoans)).to eq(2500)
      expect(payroll_run.total_claim_amount_for_policy(MathsAndPhysics)).to eq(4000)
    end
  end

  describe ".create_with_claims!" do
    let(:claims) { Policies.all.map { |policy| create(:claim, :approved, policy: policy) } }
    subject!(:payroll_run) { PayrollRun.create_with_claims!(claims, created_by: user) }

    it "creates a payroll run with payments and populates the award_amount" do
      expect(payroll_run.reload.created_by.id).to eq(user.id)
      expect(payroll_run.claims).to match_array(claims)
      expect(claims[0].payment.award_amount).to eq(claims[0].award_amount)
      expect(claims[1].payment.award_amount).to eq(claims[1].award_amount)
    end

    context "with multiple claims from the same teacher reference number" do
      let(:personal_details) do
        {
          national_insurance_number: generate(:national_insurance_number),
          teacher_reference_number: generate(:teacher_reference_number),
          email_address: generate(:email_address),
          bank_sort_code: "112233",
          bank_account_number: "95928482",
          address_line_1: "64 West Lane",
          student_loan_plan: StudentLoan::PLAN_1
        }
      end
      let(:matching_claims) do
        [
          create(:claim, :approved, personal_details.merge(policy: StudentLoans)),
          create(:claim, :approved, personal_details.merge(policy: MathsAndPhysics))
        ]
      end
      let(:other_claim) { create(:claim, :approved) }
      let(:claims) { matching_claims + [other_claim] }

      it "groups them into a single payment and populates the award_amount" do
        expect(payroll_run.payments.map(&:claims)).to match_array([match_array(matching_claims), [other_claim]])
        expect(matching_claims[0].reload.payment.award_amount).to eq(matching_claims.sum(&:award_amount))
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

  describe "#download_available?" do
    it "returns true when the download was triggered within the time limit" do
      payroll_run = create(:payroll_run, downloaded_at: Time.zone.now, downloaded_by: user)
      expect(payroll_run.download_available?).to eql true

      travel_to 31.seconds.from_now do
        expect(payroll_run.download_available?).to eql false
      end
    end

    it "returns false when the download has not been tirggered" do
      payroll_run = create(:payroll_run)

      expect(payroll_run.download_available?).to eql false
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
