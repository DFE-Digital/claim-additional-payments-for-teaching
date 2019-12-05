require "rails_helper"

RSpec.describe PayrollRun, type: :model do
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
    service_operator_id = "service_operator_id"

    travel_to confirmation_report_uploaded_time do
      payroll_run.confirmation_report_uploaded_by = service_operator_id

      expect(payroll_run.save!).to be true
      expect(payroll_run.confirmation_report_uploaded_by).eql? service_operator_id
    end
  end

  describe "#total_award_amount" do
    it "returns the sum of the award amounts of its claims" do
      payment_1 = build(:payment, claim: build(:claim, :approved, eligibility: build(:student_loans_eligibility, :eligible, student_loan_repayment_amount: 1500)))
      payment_2 = build(:payment, claim: build(:claim, :approved, eligibility: build(:student_loans_eligibility, :eligible, student_loan_repayment_amount: 2000)))

      payroll_run = PayrollRun.create!(created_by: "foo", payments: [payment_1, payment_2])

      expect(payroll_run.total_award_amount).to eq(3500)
    end
  end

  describe ".create_with_claims!" do
    let(:claims) { Policies.all.map { |policy| create(:claim, :approved, policy: policy) } }

    it "creates a payroll run with payments and populates the award_amount" do
      payroll_run = PayrollRun.create_with_claims!(claims, created_by: "creator-id")

      expect(payroll_run.reload.created_by).to eq("creator-id")
      expect(payroll_run.claims).to match_array(claims)
      expect(claims[0].payment.award_amount).to eq(claims[0].award_amount)
      expect(claims[1].payment.award_amount).to eq(claims[1].award_amount)
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
      payroll_run = create(:payroll_run, downloaded_at: Time.zone.now, downloaded_by: "admin_user_id")
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

      payroll_run.update!(downloaded_at: Time.zone.now, downloaded_by: "admin_user_id")

      expect(payroll_run.download_triggered?).to eql true
    end
  end
end
