require "rails_helper"
require Rails.root.join("db", "data", "20191015103158_add_payments_for_payrolled_claims")

RSpec.describe AddPaymentsForPayrolledClaims do
  describe "#up" do
    let!(:payroll_run) { create(:payroll_run) }

    context "for a payrolled claim without a payment" do
      let!(:first_claim) { create(:claim, :approved, payroll_run_id: payroll_run.id) }
      let!(:second_claim) { create(:claim, :approved, payroll_run_id: payroll_run.id) }

      it "creates a payment" do
        expect { described_class.new.up }.to change { Payment.count }.by(2)

        expect(first_claim.payment.payroll_run).to eq(payroll_run)
      end
    end

    context "for a payrolled claim with a payment" do
      let!(:first_claim) { create(:claim, :approved, payroll_run_id: payroll_run.id) }
      let!(:second_claim) { create(:claim, :approved) }

      before do
        [first_claim, second_claim].each do |c|
          create(:payment, claim: c, payroll_run: payroll_run)
        end
      end

      it "creates no payments" do
        expect { described_class.new.up }.not_to change { Payment.count }
      end

      it "preserves the claim's payroll run" do
        described_class.new.up

        expect(first_claim.reload.payment.payroll_run).to eq(payroll_run)
      end
    end

    context "for an unpayrolled claim" do
      let!(:claim) { create(:claim, :approved) }

      it "creates no payments" do
        expect { described_class.new.up }.not_to change { Payment.count }

        expect(claim.reload.payment).to be_nil
      end
    end
  end

  it "is irreversible" do
    expect { described_class.new.down }.to raise_error(ActiveRecord::IrreversibleMigration)
  end
end
