require "rails_helper"

RSpec.describe PaymentConfirmation do
  let(:payroll_run) { create(:payroll_run, claims_counts: {[MathsAndPhysics, StudentLoans] => 1, StudentLoans => 1}) }
  let(:csv) do
    <<~CSV
      Payroll Reference,Gross Value,Payment ID,NI,Employers NI,Student Loans,Tax,Net Pay
      DFE00001,487.48,#{payroll_run.payments[0].id},33.9,38.98,0,89.6,325
      DFE00002,"1,211.15",#{payroll_run.payments[1].id},77.84,89.51,40,162.8,534
    CSV
  end
  let(:file) do
    tempfile = Tempfile.new
    tempfile.write(csv)
    tempfile.rewind
    tempfile
  end
  let(:admin_user) { build(:dfe_signin_user) }
  let!(:dataset_post_stub) { stub_geckoboard_dataset_update("claims.test") }
  subject(:payment_confirmation) { described_class.new(payroll_run, file, admin_user) }

  context "the claims in the CSV match the claims of the payroll run" do
    it "records the values from the CSV against the claims' payments" do
      expect(payment_confirmation.ingest).to be_truthy

      first_payment = payroll_run.payments[0].reload
      second_payment = payroll_run.payments[1].reload

      expect(first_payment.payroll_reference).to eq("DFE00001")
      expect(first_payment.gross_value).to eq("487.48".to_d)
      expect(first_payment.national_insurance).to eq("33.9".to_d)
      expect(first_payment.employers_national_insurance).to eq("38.98".to_d)
      expect(first_payment.student_loan_repayment).to eq("0".to_d)
      expect(first_payment.tax).to eq("89.6".to_d)
      expect(first_payment.net_pay).to eq("325".to_d)
      expect(first_payment.gross_pay).to eq("448.5".to_d)

      expect(second_payment.payroll_reference).to eq("DFE00002")
      expect(second_payment.gross_value).to eq("1211.15".to_d)
      expect(second_payment.national_insurance).to eq("77.84".to_d)
      expect(second_payment.employers_national_insurance).to eq("89.51".to_d)
      expect(second_payment.student_loan_repayment).to eq("40".to_d)
      expect(second_payment.tax).to eq("162.8".to_d)
      expect(second_payment.net_pay).to eq("534".to_d)
      expect(second_payment.gross_pay).to eq("1121.64".to_d)
    end

    it "populates the payroll run's confirmation_report_uploaded_by and sets a payment date of the upcoming Friday" do
      a_tuesday = Date.parse("2019-01-01")
      the_following_friday = Date.parse("2019-01-04")

      travel_to a_tuesday do
        payment_confirmation.ingest
        payroll_run.reload

        expect(payroll_run.confirmation_report_uploaded_by).to eq(admin_user)
        expect(payroll_run.scheduled_payment_date).to eq(the_following_friday)
      end
    end

    it "sends payment confirmation emails with a payment date of the following Friday" do
      a_tuesday = Date.parse("2019-01-01")
      the_following_friday = "4 January 2019"
      travel_to a_tuesday do
        perform_enqueued_jobs do
          payment_confirmation.ingest
        end

        expect(ActionMailer::Base.deliveries.count).to eq(2)

        first_email = ActionMailer::Base.deliveries.first
        second_email = ActionMailer::Base.deliveries.last

        expect(first_email.to).to eq([payroll_run.payments[0].claims.first.email_address])
        expect(second_email.to).to eq([payroll_run.payments[1].claims.first.email_address])

        expect(first_email.body.raw_source).to include(the_following_friday)
        expect(second_email.body.raw_source).to include(the_following_friday)
      end
    end

    it "sends each claim's reference, policy and scheduled payment date to Geckoboard" do
      perform_enqueued_jobs do
        payment_confirmation.ingest
      end

      expect(dataset_post_stub.with { |request|
        request_body_matches_geckoboard_data_for_claims?(request, payroll_run.claims)
      }).to have_been_requested
    end
  end

  context "the value for Student Loans is blank" do
    let(:payroll_run) { create(:payroll_run, claims_counts: {StudentLoans => 1}) }
    let(:csv) do
      <<~CSV
        Payroll Reference,Gross Value,Payment ID,NI,Employers NI,Student Loans,Tax,Net Pay
        DFE00001,487.48,#{payroll_run.payments[0].id},33.9,38.98,,6,325
      CSV
    end

    it "stores a student_loan_repayment of nil" do
      expect(payment_confirmation.ingest).to be_truthy

      payment = payroll_run.payments[0].reload
      expect(payment.student_loan_repayment).to be_nil
    end
  end

  context "The payroll run has already had a Payment Confirmation Report uploaded" do
    let(:payroll_run) { create(:payroll_run, claims_counts: {StudentLoans => 2}, confirmation_report_uploaded_by: build(:dfe_signin_user)) }

    it "fails and populates its errors" do
      expect(payment_confirmation.ingest).to be_falsey
      expect(payment_confirmation.errors).to eq(["A Payment Confirmation Report has already been uploaded for this payroll run"])
    end
  end

  context "The CSV has claims that are not in the run" do
    let(:extra_claim) { create(:claim) }
    let(:csv) do
      <<~CSV
        Payroll Reference,Gross Value,Payment ID,NI,Employers NI,Student Loans,Tax,Net Pay
        DFE00001,487.48,#{payroll_run.payments[0].id},33.9,38.98,0,89.6,325
        DFE00002,904.15,#{payroll_run.payments[1].id},77.84,89.51,40,162.8,534
        DFE00003,904.15,#{extra_claim.reference},77.84,89.51,40,162.8,534
      CSV
    end

    it "fails and populates its errors, and does not update the payments" do
      expect(payment_confirmation.ingest).to be_falsey
      expect(payment_confirmation.errors).to eq(["The CSV file contains a payment that is not part of the payroll run at line 4"])

      expect(payroll_run.payments[0].reload.payroll_reference).to eq(nil)
      expect(payroll_run.payments[1].reload.payroll_reference).to eq(nil)
    end
  end

  context "The CSV has a claim missing from the run" do
    let(:csv) do
      <<~CSV
        Payroll Reference,Gross Value,Payment ID,NI,Employers NI,Student Loans,Tax,Net Pay
        DFE00001,487.48,#{payroll_run.payments[0].id},33.9,38.98,0,89.6,325
      CSV
    end

    it "fails and populates its errors, and does not update the payments" do
      expect(payment_confirmation.ingest).to be_falsey
      expect(payment_confirmation.errors).to eq([
        "Payment ID #{payroll_run.payments[1].id} is missing from the file. Please check with Cantium to see if there is a problem with this payment. You may need to remove some payments from the Payroll Run then try uploading it again"
      ])

      expect(payroll_run.payments[0].reload.payroll_reference).to eq(nil)
      expect(payroll_run.payments[1].reload.payroll_reference).to eq(nil)
    end
  end

  context "The CSV has a duplicate claim" do
    let(:csv) do
      <<~CSV
        Payroll Reference,Gross Value,Payment ID,NI,Employers NI,Student Loans,Tax,Net Pay
        DFE00001,487.48,#{payroll_run.payments[0].id},33.9,38.98,0,89.6,325
        DFE00002,904.15,#{payroll_run.payments[1].id},77.84,89.51,40,162.8,534
        DFE00002,904.15,#{payroll_run.payments[1].id},77.84,89.51,40,162.8,534
      CSV
    end

    it "fails and populates its errors, and does not update the payments" do
      expect(payment_confirmation.ingest).to be_falsey
      expect(payment_confirmation.errors).to eq(["The payment with ID #{payroll_run.payments[1].id} is repeated at line 4"])

      expect(payroll_run.payments[0].reload.payroll_reference).to eq(nil)
      expect(payroll_run.payments[1].reload.payroll_reference).to eq(nil)
    end

    it "does not queue emails" do
      expect { payment_confirmation.ingest }.to_not have_enqueued_job
    end
  end

  context "The CSV has a blank value for a required field" do
    let(:csv) do
      <<~CSV
        Payroll Reference,Gross Value,Payment ID,NI,Employers NI,Student Loans,Tax,Net Pay
        DFE00001,,#{payroll_run.payments[0].id},,38.98,0,89.6,325
        DFE00002,904.15,#{payroll_run.payments[1].id},77.84,89.51,40,162.8,534
      CSV
    end

    it "fails and populates its errors, and does not update the payments" do
      expect(payment_confirmation.ingest).to be_falsey
      expect(payment_confirmation.errors).to eq(["The claim at line 2 has invalid data - Gross value can't be blank and National insurance can't be blank"])

      expect(payroll_run.payments[0].reload.payroll_reference).to eq(nil)
      expect(payroll_run.payments[1].reload.payroll_reference).to eq(nil)
    end

    it "does not queue emails" do
      expect { payment_confirmation.ingest }.to_not have_enqueued_job
    end
  end
end
