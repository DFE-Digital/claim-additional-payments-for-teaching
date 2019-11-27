require "rails_helper"

RSpec.describe "Admin payroll runs" do
  context "when signed in as a service operator" do
    let(:admin_session_id) { "some_user_id" }
    before do
      sign_in_to_admin_with_role(AdminSession::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE, admin_session_id)
    end

    describe "admin_payroll_runs#new" do
      it "displays a preview of the payrollable claims" do
        create(:claim, :approved, eligibility: create(:student_loans_eligibility, student_loan_repayment_amount: 100))

        get new_admin_payroll_run_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("£100")
      end
    end

    describe "admin_payroll_runs#create" do
      it "creates a payroll run with payments and redirects to it" do
        claims = create_list(:claim, 2, :approved)

        expect { post admin_payroll_runs_path(claim_ids: claims.map(&:id)) }.to change { PayrollRun.count }.by(1)

        payroll_run = PayrollRun.order(:created_at).last
        expect(payroll_run.created_by).to eq(admin_session_id)
        expect(payroll_run.claims).to match_array(claims)
        expect(payroll_run.payments.count).to eq(2)

        expect(response).to redirect_to(admin_payroll_run_path(payroll_run))
      end
    end

    describe "admin_payroll_runs#show" do
      it "returns a csv containing the claims from the given payroll run" do
        payroll_run = create(:payroll_run, claims_counts: {StudentLoans => 3})

        create_list(:claim, 2, :approved)

        get admin_payroll_run_path(payroll_run, format: :csv)

        csv = CSV.parse(body, headers: true)

        expect(csv.map { |row| row["CLAIM_ID"] }).to match_array(payroll_run.claims.map(&:reference))
      end
    end
  end

  context "when signed in as a support user" do
    before do
      sign_in_to_admin_with_role(AdminSession::SUPPORT_AGENT_DFE_SIGN_IN_ROLE_CODE)
    end

    describe "admin_payroll_runs#new" do
      it "returns a unauthorized response" do
        get new_admin_payroll_run_path

        expect(response).to have_http_status(:unauthorized)
      end
    end

    describe "admin_payroll_runs#create" do
      it "does not create a payroll run and returns a unauthorized response" do
        expect { post admin_payroll_runs_path }.to_not change { PayrollRun.count }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
