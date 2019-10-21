require "rails_helper"

RSpec.describe PaymentConfirmation do
  let(:payroll_run) { create(:payroll_run, claims_count: 2) }
  let(:csv) do
    <<~CSV
      Payroll Reference,Gross Value,Claim ID,NI,Employers NI,Student Loans,Tax,Net Pay
      DFE00001,487.48,#{payroll_run.claims[0].reference},33.9,38.98,0,89.6,325
      DFE00002,904.15,#{payroll_run.claims[1].reference},77.84,89.51,40,162.8,534
    CSV
  end
  let(:file) do
    tempfile = Tempfile.new
    tempfile.write(csv)
    tempfile.rewind
    tempfile
  end
  let(:admin_user_id) { "uploader-id" }
  subject(:payment_confirmation) { described_class.new(payroll_run, file, admin_user_id) }

  context "the claims in the CSV match the claims of the payroll run" do
    it "records the values from the CSV against the claims' payments, and populates the payroll run's confirmation_report_uploaded_by" do
      expect(payment_confirmation.ingest).to be_truthy

      first_payment = payroll_run.claims[0].payment.reload
      second_payment = payroll_run.claims[1].payment.reload

      expect(first_payment.payroll_reference).to eq("DFE00001")
      expect(first_payment.gross_value).to eq("487.48".to_d)
      expect(first_payment.national_insurance).to eq("33.9".to_d)
      expect(first_payment.employers_national_insurance).to eq("38.98".to_d)
      expect(first_payment.student_loan_repayment).to eq("0".to_d)
      expect(first_payment.tax).to eq("89.6".to_d)
      expect(first_payment.net_pay).to eq("325".to_d)

      expect(second_payment.payroll_reference).to eq("DFE00002")
      expect(second_payment.gross_value).to eq("904.15".to_d)
      expect(second_payment.national_insurance).to eq("77.84".to_d)
      expect(second_payment.employers_national_insurance).to eq("89.51".to_d)
      expect(second_payment.student_loan_repayment).to eq("40".to_d)
      expect(second_payment.tax).to eq("162.8".to_d)
      expect(second_payment.net_pay).to eq("534".to_d)

      expect(payroll_run.reload.confirmation_report_uploaded_by).to eq(admin_user_id)
    end
  end

  context "the value for Student Loans is blank" do
    let(:payroll_run) { create(:payroll_run, claims_count: 1) }
    let(:csv) do
      <<~CSV
        Payroll Reference,Gross Value,Claim ID,NI,Employers NI,Student Loans,Tax,Net Pay
        DFE00001,487.48,#{payroll_run.claims[0].reference},33.9,38.98,,6,325
      CSV
    end

    it "stores a student_loan_repayment of nil" do
      expect(payment_confirmation.ingest).to be_truthy

      payment = payroll_run.claims[0].payment.reload
      expect(payment.student_loan_repayment).to be_nil
    end
  end

  context "The payroll run has already had a Payment Confirmation Report uploaded" do
    let(:payroll_run) { create(:payroll_run, claims_count: 2, confirmation_report_uploaded_by: "some-user-id") }

    it "fails and populates its errors" do
      expect(payment_confirmation.ingest).to be_falsey
      expect(payment_confirmation.errors).to eq(["A Payment Confirmation Report has already been uploaded for this payroll run"])
    end
  end

  context "The CSV has claims that are not in the run" do
    let(:extra_claim) { create(:claim) }
    let(:csv) do
      <<~CSV
        Payroll Reference,Gross Value,Claim ID,NI,Employers NI,Student Loans,Tax,Net Pay
        DFE00001,487.48,#{payroll_run.claims[0].reference},33.9,38.98,0,89.6,325
        DFE00002,904.15,#{payroll_run.claims[1].reference},77.84,89.51,40,162.8,534
        DFE00003,904.15,#{extra_claim.reference},77.84,89.51,40,162.8,534
      CSV
    end

    it "fails and populates its errors, and does not update the payments" do
      expect(payment_confirmation.ingest).to be_falsey
      expect(payment_confirmation.errors).to eq(["The CSV file contains a claim that is not part of the payroll run at line 4"])

      expect(payroll_run.claims[0].payment.reload.payroll_reference).to eq(nil)
      expect(payroll_run.claims[1].payment.reload.payroll_reference).to eq(nil)
    end
  end

  context "The CSV has a claim missing from the run" do
    let(:csv) do
      <<~CSV
        Payroll Reference,Gross Value,Claim ID,NI,Employers NI,Student Loans,Tax,Net Pay
        DFE00001,487.48,#{payroll_run.claims[0].reference},33.9,38.98,0,89.6,325
      CSV
    end

    it "fails and populates its errors, and does not update the payments" do
      expect(payment_confirmation.ingest).to be_falsey
      expect(payment_confirmation.errors).to eq(["The claim ID #{payroll_run.claims[1].reference} is missing from the CSV"])

      expect(payroll_run.claims[0].payment.reload.payroll_reference).to eq(nil)
      expect(payroll_run.claims[1].payment.reload.payroll_reference).to eq(nil)
    end
  end

  context "The CSV has a duplicate claim" do
    let(:csv) do
      <<~CSV
        Payroll Reference,Gross Value,Claim ID,NI,Employers NI,Student Loans,Tax,Net Pay
        DFE00001,487.48,#{payroll_run.claims[0].reference},33.9,38.98,0,89.6,325
        DFE00002,904.15,#{payroll_run.claims[1].reference},77.84,89.51,40,162.8,534
        DFE00002,904.15,#{payroll_run.claims[1].reference},77.84,89.51,40,162.8,534
      CSV
    end

    it "fails and populates its errors, and does not update the payments" do
      expect(payment_confirmation.ingest).to be_falsey
      expect(payment_confirmation.errors).to eq(["The claim ID #{payroll_run.claims[1].reference} is repeated at line 4"])

      expect(payroll_run.claims[0].payment.reload.payroll_reference).to eq(nil)
      expect(payroll_run.claims[1].payment.reload.payroll_reference).to eq(nil)
    end
  end

  context "The CSV has a blank value for a required field" do
    let(:csv) do
      <<~CSV
        Payroll Reference,Gross Value,Claim ID,NI,Employers NI,Student Loans,Tax,Net Pay
        DFE00001,,#{payroll_run.claims[0].reference},33.9,38.98,0,89.6,325
        DFE00002,904.15,#{payroll_run.claims[1].reference},77.84,89.51,40,162.8,534
      CSV
    end

    it "fails and populates its errors, and does not update the payments" do
      expect(payment_confirmation.ingest).to be_falsey
      expect(payment_confirmation.errors).to eq(["The claim at line 2 has invalid data"])

      expect(payroll_run.claims[0].payment.reload.payroll_reference).to eq(nil)
      expect(payroll_run.claims[1].payment.reload.payroll_reference).to eq(nil)
    end
  end
end
