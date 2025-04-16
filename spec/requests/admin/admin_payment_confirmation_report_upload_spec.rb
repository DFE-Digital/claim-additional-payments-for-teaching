require "rails_helper"

RSpec.describe "Admin Payment Confirmation Report upload" do
  let(:payroll_run) { create(:payroll_run) }

  context "when signed in as a service operator" do
    before { @signed_in_user = sign_in_as_service_operator }

    describe "payment_confirmation_report_uploads#new" do
      it "returns an OK response" do
        get new_admin_payroll_run_payment_confirmation_report_upload_path(payroll_run)

        expect(response).to have_http_status(:ok)
      end
    end

    describe "payment_confirmation_report_uploads#create" do
      let(:file) { Rack::Test::UploadedFile.new(StringIO.new(csv), "text/csv", original_filename: "payments.csv") }

      context "the claims in the CSV match the claims of the payroll run" do
        let(:payroll_run) { create(:payroll_run, claims_counts: {Policies::StudentLoans => 2}) }
        let(:csv) do
          <<~CSV
            Payroll Reference,Gross Value,Payment ID,NI,Employers NI,Student Loans,Tax,Net Pay,Claim Policies,Postgraduate Loans,Payment Date
            DFE00001,487.48,#{payroll_run.payments[0].id},33.9,38.98,0,89.6,325,StudentLoans,,17/07/2023
            DFE00002,904.15,#{payroll_run.payments[1].id},77.84,89.51,40,162.8,534,StudentLoans,,17/07/2023
          CSV
        end

        it "records the values from the CSV against the claims' payments, sends emails" do
          perform_enqueued_jobs do
            post admin_payroll_run_payment_confirmation_report_uploads_path(payroll_run), params: {file: file}
          end

          expect(response).to redirect_to(admin_payroll_runs_path)

          expect(payroll_run.payments[0].reload.payroll_reference).to eq("DFE00001")
          expect(payroll_run.payments[1].reload.payroll_reference).to eq("DFE00002")

          expect(payroll_run.reload.payment_confirmations[0].created_by).to eq(@signed_in_user)

          expect(ActionMailer::Base.deliveries.count).to eq(2)
        end
      end

      context "the CSV has invalid data" do
        let(:payroll_run) { create(:payroll_run, claims_counts: {Policies::StudentLoans => 2}) }
        let(:csv) do
          <<~CSV
            Payroll Reference,Gross Value,Payment ID,NI,Employers NI,Student Loans,Tax,Net Pay,Claim Policies,Postgraduate Loans,Payment Date
            DFE00001,487.48,#{payroll_run.payments[0].id},33.9,38.98,0,89.6,325,StudentLoans,,17/07/2023
            DFE00002,904.15,#{payroll_run.payments[1].id},77.84,89.51,40,162.8,,,17/07/2023
          CSV
        end

        it "displays errors and does not send emails" do
          perform_enqueued_jobs do
            post admin_payroll_run_payment_confirmation_report_uploads_path(payroll_run), params: {file: file}
          end

          expect(response).to have_http_status(:ok)
          expect(response.body).to include("The claim at line 3 has invalid data")
          expect(ActionMailer::Base.deliveries.count).to eq(0)
        end
      end

      context "the CSV is not present" do
        it "displays an error message" do
          post admin_payroll_run_payment_confirmation_report_uploads_path(payroll_run)

          expect(response).to have_http_status(:ok)
          expect(response.body).to include("Select a file")
        end
      end
    end
  end

  context "when signed in as a support agent" do
    describe "payment_confirmation_report_uploads#new" do
      it "returns an unauthorized response" do
        sign_in_to_admin_with_role(DfeSignIn::User::SUPPORT_AGENT_DFE_SIGN_IN_ROLE_CODE)

        get new_admin_payroll_run_payment_confirmation_report_upload_path(payroll_run)

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
