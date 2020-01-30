require "rails_helper"

RSpec.describe "Admin payroll runs" do
  context "when signed in as a service operator" do
    let(:user) { create(:dfe_signin_user) }

    before do
      sign_in_to_admin_with_role(DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE, user.dfe_sign_in_id)
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
        expect(payroll_run.created_by.id).to eq(user.id)
        expect(payroll_run.claims).to match_array(claims)
        expect(payroll_run.payments.count).to eq(2)

        expect(response).to redirect_to(admin_payroll_run_path(payroll_run))
      end

      context "when a payroll run contains claims from the same person with different bank details" do
        it "doesn’t create a payroll run and shows an error" do
          personal_details = {
            teacher_reference_number: generate(:teacher_reference_number),
            bank_sort_code: "112233",
          }
          claims = [
            create(:claim, :approved, personal_details.merge(bank_account_number: "12345678")),
            create(:claim, :approved, personal_details.merge(bank_account_number: "99999999")),
          ]

          expect { post admin_payroll_runs_path(claim_ids: claims.map(&:id)) }.to change { PayrollRun.count }.by(0)
          follow_redirect!
          expect(response.body).to include("Claims #{claims[0].reference} and #{claims[1].reference} have different values for bank account number")
        end
      end
    end

    describe "admin_payroll_runs#show" do
      it "displays a payroll run showing a link to the payroll run download" do
        payroll_run = create(:payroll_run)

        get admin_payroll_run_path(payroll_run)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include new_admin_payroll_run_download_url(payroll_run)
      end

      it "does not show the link to the payroll run download once the download has been triggered" do
        payroll_run = create(:payroll_run, downloaded_at: Time.zone.now, downloaded_by: user)

        get admin_payroll_run_path(payroll_run)

        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include new_admin_payroll_run_download_url(payroll_run)
      end

      it "shows who downloaded the payroll run once the download has been triggered" do
        payroll_run = create(:payroll_run, downloaded_at: Time.zone.now, downloaded_by: user)

        get admin_payroll_run_path(payroll_run)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.l(payroll_run.downloaded_at))
        expect(response.body).to include(user.full_name)
      end
    end
  end

  context "when signed in as a payroll operator or a support agent" do
    [DfeSignIn::User::SUPPORT_AGENT_DFE_SIGN_IN_ROLE_CODE, DfeSignIn::User::PAYROLL_OPERATOR_DFE_SIGN_IN_ROLE_CODE].each do |role|
      before do
        sign_in_to_admin_with_role(role)
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

      describe "admin_payroll_runs#show" do
        it "does not view a payroll run and returns a unauthorized response" do
          payroll_run = create(:payroll_run)

          get admin_payroll_run_path(payroll_run)

          expect(response).to have_http_status(:unauthorized)
        end
      end
    end
  end
end
