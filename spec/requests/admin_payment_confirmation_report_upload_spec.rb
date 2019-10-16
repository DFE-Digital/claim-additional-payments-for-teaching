require "rails_helper"

RSpec.describe "Admin Payment Confirmation Report upload" do
  let(:payroll_run) { create(:payroll_run) }

  context "when signed in as a service operator" do
    let(:admin_session_id) { "some_user_id" }
    before do
      sign_in_to_admin_with_role(AdminSession::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE, admin_session_id)
    end

    describe "payment_confirmation_report_uploads#new" do
      it "returns an OK response" do
        get new_admin_payroll_run_payment_confirmation_report_upload_path(payroll_run)

        expect(response).to have_http_status(:ok)
      end
    end

    describe "payment_confirmation_report_uploads#create" do
      let(:file) { Rack::Test::UploadedFile.new(StringIO.new(csv), "text/csv", original_filename: "payments.csv") }

      context "the claims in the CSV match the claims of the payroll run" do
        let(:claims) { create_list(:claim, 2, :approved) }
        before do
          claims.each { |c| create(:payment, claim: c, payroll_run: payroll_run) }
        end
        let(:csv) do
          <<~CSV
            Payroll Reference,Gross Value,Claim ID,NI,Employers NI,Student Loans,Tax,Net Pay
            DFE00001,487.48,#{claims[0].reference},33.9,38.98,0,89.6,325
            DFE00002,904.15,#{claims[1].reference},77.84,89.51,40,162.8,534
          CSV
        end

        it "records the values from the CSV against the claims' payments" do
          post admin_payroll_run_payment_confirmation_report_uploads_path(payroll_run), params: {file: file}

          expect(response).to redirect_to(admin_payroll_runs_path)

          expect(claims[0].reload.payment.payroll_reference).to eq("DFE00001")
          expect(claims[1].reload.payment.payroll_reference).to eq("DFE00002")

          expect(payroll_run.reload.confirmation_report_uploaded_by).to eq(admin_session_id)
        end
      end

      context "the CSV contains an error" do
        let(:csv) do
          <<~CSV
            Payroll Referee,Gross Value,Claim ID,NI,Employers NI,Studently Loans,Tax,Net Pay
          CSV
        end

        it "displays the errors" do
          post admin_payroll_run_payment_confirmation_report_uploads_path(payroll_run), params: {file: file}

          expect(response).to have_http_status(:ok)
          expect(response.body).to include("The selected file is missing some expected columns")
        end
      end

      context "the CSV is not present" do
        it "displays an error message" do
          post admin_payroll_run_payment_confirmation_report_uploads_path(payroll_run)

          expect(response).to have_http_status(:ok)
          expect(response.body).to include("You must provide a file")
        end
      end
    end
  end

  context "when signed in as a support user" do
    before do
      sign_in_to_admin_with_role(AdminSession::SUPPORT_AGENT_DFE_SIGN_IN_ROLE_CODE)
    end

    describe "payment_confirmation_report_uploads#new" do
      it "returns an unauthorized response" do
        get new_admin_payroll_run_payment_confirmation_report_upload_path(payroll_run)

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
