require "rails_helper"

RSpec.describe PaymentConfirmationUpload do
  subject(:payment_confirmation_upload) do
    described_class.new(payroll_run, file, admin_user)
  end

  let(:admin_user) { build(:dfe_signin_user) }
  let(:payroll_run) do
    create(:payroll_run, claims_counts: {
      [Policies::EarlyCareerPayments, Policies::StudentLoans] => 1,
      Policies::StudentLoans => 1,
      Policies::EarlyCareerPayments => 2
    })
  end

  let(:first_payment) { payroll_run.payments.ordered[0].reload }
  let(:second_payment) { payroll_run.payments.ordered[1].reload }
  let(:third_payment) { payroll_run.payments.ordered[2].reload }
  let(:skipped_payment) { payroll_run.payments.ordered[3].reload }

  let(:csv) do
    <<~CSV
      Payroll Reference,Gross Value,Payment ID,NI,Employers NI,Student Loans,Tax,Net Pay,Claim Policies,Postgraduate Loans,Payment Date
      DFE00001,448.5,#{first_payment.id},33.9,38.98,0,89.6,325,StudentLoans,0,17/07/2023
      DFE00002,814.64,#{second_payment.id},77.84,89.51,40,162.8,534,"EarlyCareerPayments,StudentLoans",0,17/07/2023
      DFE00003,9710.83,#{third_payment.id},268.84,1316.63,839,1942,6660.99,EarlyCareerPayments,9710.83,17/07/2023
    CSV
  end

  let(:file) do
    Tempfile.new.tap do |file|
      file.write(csv)
      file.rewind
    end
  end

  describe "#ingest" do
    shared_examples "successful upload" do
      it { expect(payment_confirmation_upload.ingest).to be_truthy }

      it "creates a confirmation" do
        expect { payment_confirmation_upload.ingest }
          .to change(PaymentConfirmation, :count).by(1)
      end
    end

    shared_examples "unsuccessful upload" do
      it { expect(payment_confirmation_upload.ingest).to be_falsey }

      it "does not update the payments", :aggregate_failures do
        payment_confirmation_upload.ingest

        expect(first_payment.reload.payroll_reference).to be_nil
        expect(second_payment.reload.payroll_reference).to be_nil
        expect(third_payment.reload.payroll_reference).to be_nil
      end

      it "does not create a confirmation", :aggregate_failures do
        expect { payment_confirmation_upload.ingest }
          .to_not change(PaymentConfirmation, :count)
      end

      it "does not enqueue confirmation emails" do
        expect { payment_confirmation_upload.ingest }
          .to_not have_enqueued_job(PaymentMailer)
      end

      it "populates the errors" do
        payment_confirmation_upload.ingest

        expect(payment_confirmation_upload.errors).to eq(expected_errors)
      end
    end

    context "when all the payments in the CSV belong to the payroll run" do
      before do
        allow(PaymentMailer).to receive(:confirmation)
          .and_return(double(deliver_later: nil))
      end

      it_behaves_like "successful upload"

      it "records the values from the CSV against the claims' payments" do
        payment_confirmation_upload.ingest

        aggregate_failures do
          expect(first_payment.reload).to have_attributes(
            payroll_reference: "DFE00001",
            gross_value: "487.48".to_d,
            national_insurance: "33.9".to_d,
            employers_national_insurance: "38.98".to_d,
            student_loan_repayment: 0.to_d,
            postgraduate_loan_repayment: 0.to_d,
            tax: "89.6".to_d,
            net_pay: 325.to_d,
            gross_pay: "448.5".to_d
          )

          expect(second_payment.reload).to have_attributes(
            payroll_reference: "DFE00002",
            gross_value: "904.15".to_d,
            national_insurance: "77.84".to_d,
            employers_national_insurance: "89.51".to_d,
            student_loan_repayment: 40.to_d,
            postgraduate_loan_repayment: 0.to_d,
            tax: "162.8".to_d,
            net_pay: 534.to_d,
            gross_pay: "814.64".to_d
          )

          expect(third_payment.reload).to have_attributes(
            payroll_reference: "DFE00003",
            gross_value: "11_027.46".to_d,
            national_insurance: "268.84".to_d,
            employers_national_insurance: "1316.63".to_d,
            student_loan_repayment: 839.to_d,
            postgraduate_loan_repayment: "9710.83".to_d,
            tax: 1942.to_d,
            net_pay: "6660.99".to_d,
            gross_pay: "9710.83".to_d
          )
        end
      end

      it "does not update the claims' payments of the payroll run that are not uploaded" do
        payment_confirmation_upload.ingest

        expect(skipped_payment.reload).to have_attributes(
          payroll_reference: nil,
          gross_value: nil,
          national_insurance: nil,
          employers_national_insurance: nil,
          student_loan_repayment: nil,
          postgraduate_loan_repayment: nil,
          tax: nil,
          net_pay: nil,
          gross_pay: nil
        )
      end

      it "creates a payment confirmation with the scheduled payment date from the CSV" do
        payment_confirmation_upload.ingest
        payroll_run.reload

        confirmation = payroll_run.payment_confirmations.first
        confirmed_payments = payroll_run.payments - [skipped_payment]

        aggregate_failures do
          expect(payroll_run.payment_confirmations.count).to eq(1)

          expect(confirmation).to have_attributes(
            payroll_run_id: payroll_run.id,
            created_by_id: admin_user.id
          )

          expect(confirmed_payments).to all(have_attributes(
            confirmation_id: confirmation.id,
            scheduled_payment_date: Date.parse("17/07/2023")
          ))
        end
      end

      it "sends payment confirmation emails" do
        payment_confirmation_upload.ingest

        aggregate_failures do
          expect(PaymentMailer)
            .not_to have_received(:confirmation).with(skipped_payment)

          (payroll_run.payments - [skipped_payment]).each do |payment|
            expect(PaymentMailer).to have_received(:confirmation).with(payment)
          end
        end
      end
    end

    context "when one payment in the CSV does not belong to the payroll run" do
      let(:csv) do
        <<~CSV
          Payroll Reference,Gross Value,Payment ID,NI,Employers NI,Student Loans,Tax,Net Pay,Claim Policies,Postgraduate Loans,Payment Date
          DFE00001,448.5,#{first_payment.id},33.9,38.98,0,89.6,325,StudentLoans,0,17/07/2023
          DFE00002,814.64,#{second_payment.id},77.84,89.51,40,162.8,534,StudentLoans,0,17/07/2023
          DFE00003,9710.83,#{third_payment.id},268.84,1316.63,839,1942,6660.99,EarlyCareerPayments,9710.83,17/07/2023
          DFE00004,814.64,UNRELATED,77.84,89.51,40,162.8,534,StudentLoans,0,17/07/2023
        CSV
      end

      let(:expected_errors) do
        ["The CSV file contains a payment that is already confirmed or not part of the payroll run at line 5"]
      end

      it_behaves_like "unsuccessful upload"
    end

    context "when the value for Student Loans is blank in the CSV" do
      let(:payroll_run) { create(:payroll_run, claims_counts: {Policies::StudentLoans => 1}) }
      let(:csv) do
        <<~CSV
          Payroll Reference,Gross Value,Payment ID,NI,Employers NI,Student Loans,Tax,Net Pay,Claim Policies,Postgraduate Loans,Payment Date
          DFE00001,448.5,#{first_payment.id},33.9,38.98,,89.6,325,StudentLoans,,17/07/2023
        CSV
      end

      it_behaves_like "successful upload"

      it "stores a student_loan_repayment of nil" do
        payment_confirmation_upload.ingest

        expect(first_payment.reload.student_loan_repayment).to be_nil
      end
    end

    context "when the payments in the CSV have all been confirmed already" do
      let!(:payroll_run) do
        create(:payroll_run, :with_confirmations, claims_counts: {
          Policies::StudentLoans => 2, Policies::EarlyCareerPayments => 1
        })
      end

      let(:expected_errors) do
        ["A Payment Confirmation Report for all payments has already been uploaded for this payroll run"]
      end

      it_behaves_like "unsuccessful upload"
    end

    context "when some payments in the CSV that have been confirmed already" do
      let!(:payroll_run) do
        create(:payroll_run, :with_confirmations, confirmed_batches: 1, claims_counts: {
          Policies::StudentLoans => 2, Policies::EarlyCareerPayments => 1
        })
      end

      let(:csv) do
        <<~CSV
          Payroll Reference,Gross Value,Payment ID,NI,Employers NI,Student Loans,Tax,Net Pay,Claim Policies,Postgraduate Loans,Payment Date
          DFE00001,448.5,#{first_payment.id},33.9,38.98,0,89.6,325,StudentLoans,0,17/07/2023
          DFE00002,814.64,#{second_payment.id},77.84,89.51,40,162.8,534,StudentLoans,0,17/07/2023
          DFE00003,9710.83,#{third_payment.id},268.84,1316.63,839,1942,6660.99,EarlyCareerPayments,9710.83,17/07/2023
        CSV
      end

      let(:expected_errors) do
        [
          "The CSV file contains a payment that is already confirmed or not part of the payroll run at line 2",
          "The CSV file contains a payment that is already confirmed or not part of the payroll run at line 3"
        ]
      end

      it_behaves_like "unsuccessful upload"
    end

    context "when some payments in the payroll run are missing from the CSV" do
      let(:csv) do
        <<~CSV
          Payroll Reference,Gross Value,Payment ID,NI,Employers NI,Student Loans,Tax,Net Pay,Claim Policies,Postgraduate Loans,Payment Date
          DFE00001,448.5,#{first_payment.id},33.9,38.98,0,89.6,325,EarlyCareerPayments,,17/07/2023
          DFE00003,9710.83,#{third_payment.id},268.84,1316.63,839,1942,6660.99,EarlyCareerPayments,9710.83,17/07/2023
        CSV
      end

      it_behaves_like "successful upload"

      it "updates the payments from the CSV only", :aggregate_failures do
        payment_confirmation_upload.ingest

        expect(first_payment.reload.payroll_reference).to eq("DFE00001")
        expect(second_payment.reload.payroll_reference).to eq(nil)
        expect(third_payment.reload.payroll_reference).to eq("DFE00003")
      end
    end

    context "when the CSV has a duplicate payment" do
      let(:csv) do
        <<~CSV
          Payroll Reference,Gross Value,Payment ID,NI,Employers NI,Student Loans,Tax,Net Pay,Claim Policies,Postgraduate Loans,Payment Date
          DFE00001,448.5,#{first_payment.id},33.9,38.98,0,89.6,325,StudentLoans,,17/07/2023
          DFE00002,814.64,#{second_payment.id},77.84,89.51,40,162.8,534,StudentLoans,,17/07/2023
          DFE00002,814.64,#{second_payment.id},77.84,89.51,40,162.8,534,StudentLoans,0,17/07/2023
          DFE00003,9710.83,#{third_payment.id},268.84,1316.63,839,1942,6660.99,EarlyCareerPayments,9710.83,17/07/2023
        CSV
      end

      let(:expected_errors) do
        ["The payment with ID #{second_payment.id} is repeated at line 4"]
      end

      it_behaves_like "unsuccessful upload"
    end

    context "when the CSV has a blank value for a required field" do
      let(:csv) do
        <<~CSV
          Payroll Reference,Gross Value,Payment ID,NI,Employers NI,Student Loans,Tax,Net Pay,Claim Policies,Postgraduate Loans,Payment Date
          DFE00001,,#{first_payment.id},,38.98,0,0,89.6,StudentLoans,,17/07/2023
          DFE00002,814.64,#{second_payment.id},77.84,89.51,40,162.8,534,StudentLoans,0,17/07/2023
          DFE00003,9710.83,#{third_payment.id},268.84,1316.63,839,1942,6660.99,EarlyCareerPayments,9710.83,17/07/2023
        CSV
      end

      let(:expected_errors) do
        ["The claim at line 2 has invalid data - National insurance can't be blank and Gross pay can't be blank"]
      end

      it_behaves_like "unsuccessful upload"
    end

    context "when CSV has superfluous empty rows" do
      let(:csv) do
        <<~CSV
          Payroll Reference,Gross Value,Payment ID,NI,Employers NI,Student Loans,Tax,Net Pay,Claim Policies,Postgraduate Loans,Payment Date
          DFE00001,448.5,#{first_payment.id},33.9,38.98,0,89.6,325,StudentLoans,0,17/07/2023

          DFE00002,814.64,#{second_payment.id},77.84,89.51,40,162.8,534,"EarlyCareerPayments,StudentLoans",0,17/07/2023

          DFE00003,9710.83,#{third_payment.id},268.84,1316.63,839,1942,6660.99,EarlyCareerPayments,9710.83,17/07/2023

        CSV
      end

      it_behaves_like "successful upload"
    end
  end
end
